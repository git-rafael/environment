---
name: ha-app-creator
description: "Create Home Assistant addons from Docker images or docker-compose files. Use this skill whenever the user wants to create a HA addon, convert a docker-compose to a HA addon, package a web app for Home Assistant, or add authentication (Traefik + TinyAuth) to a self-hosted app running on HA. Also trigger when the user mentions 'HA addon', 'Home Assistant add-on', 'hassio addon', or wants to self-host an app on their Home Assistant instance."
---

# Home Assistant Addon Creator

Create production-ready Home Assistant addons from Docker images or docker-compose files, with optional Google OAuth authentication via Traefik + TinyAuth.

## Workflow

### Step 1: Gather Requirements

Ask the user:

1. **What app?** Get the Docker image name, docker-compose file, or GitHub repo.
2. **Authentication needed?** If yes, provision Traefik as reverse proxy + TinyAuth for Google OAuth.
3. **What ports?** Identify which ports the app exposes (web UI, API, etc.).
4. **What data to persist?** Identify volumes/data directories that need to survive rebuilds.
5. **Git sync needed?** If the app manages files (wiki, notes, etc.), offer git sync with GitHub.
6. **App-specific options?** Any environment variables the user wants configurable from the HA UI.

### Step 2: Determine Base Image Strategy

There are two approaches — choose based on the app's base OS:

**Strategy A: HA base image (Alpine)** — Use when the app is a single static binary or Alpine-compatible. Requires `build.yaml`.
- Use `COPY --from=<app-image>` to extract binaries into the HA Alpine base.
- Requires `ARG BUILD_FROM` and `build.yaml` with HA base images.

**Strategy B: App image as base** — Use when the app has complex runtime dependencies (Python, Node.js, system libs). Simpler and more reliable.
- Use the app's own Docker image as `FROM` base.
- No `build.yaml` needed.
- Must add `CMD ["/init"]` to override the app's default entrypoint.
- Must install `jq` (needed to parse `/data/options.json`).
- Check if the image supports both amd64 and aarch64: `docker manifest inspect <image>`.

### Step 3: Generate Files

Create the addon directory with this structure:

```
my-addon/
├── build.yaml      # Only if using Strategy A
├── config.yaml     # Addon metadata + user options
├── Dockerfile      # Multi-stage build
├── init            # Bash entrypoint script
├── icon.png        # 256x256 addon icon
└── logo.png        # 256x256 addon logo
```

Read the reference files for templates:
- `references/templates-auth.md` — Templates for addons WITH authentication (Traefik + TinyAuth)
- `references/templates-noauth.md` — Templates for addons WITHOUT authentication

### Step 4: Handle Data Persistence

All persistent data MUST go under `/data/` inside the container. The HA Supervisor automatically mounts a persistent volume there. Data in any other path is lost on rebuild.

If the app stores data outside `/data/`, create symlinks in the init script:

```bash
mkdir -p /data/myapp-db
rm -rf /original/path
ln -s /data/myapp-db /original/path
```

The `rm -rf` is necessary because the directory may already exist in the Docker image and `ln -s` won't replace a directory.

### Step 5: Validate Required Options

Add validation at the top of the init script to fail fast if required options are missing. HA does not prevent starting an addon with empty required fields.

```bash
OPTIONS="/data/options.json"
REQUIRED="host google_client_id google_client_secret"
for key in $REQUIRED; do
  val=$(jq -r ".$key" "$OPTIONS")
  if [ -z "$val" ] || [ "$val" = "null" ]; then
    echo "[init] ERROR: required option '$key' is not set. Configure it in the addon settings." >&2
    exit 1
  fi
done
```

### Step 6: Deploy and Test

Deploy to the HA server:

```bash
# Copy files to the addons directory (use * to avoid creating a subdirectory)
scp -r my-addon/* root@<ha-host>:/addons/my-addon/

# First install
ha apps install local_my-addon

# For updates: remove old image to bust cache, then rebuild
docker rmi -f $(docker images -q --filter 'reference=*my-addon*')
ha apps rebuild local_my-addon

# Start and check logs
ha apps start local_my-addon
docker logs addon_local_my-addon
```

## Key Lessons and Gotchas

### HA Supervisor and PID 1
The HA Supervisor injects `--init` (tini as PID 1) regardless of `init: false` in config.yaml. This breaks s6-overlay which requires being PID 1. The solution is a custom bash `/init` entrypoint that starts services as background processes and uses `wait -n` to monitor them.

### Port Conflicts
Without `host_network: true` (which should be avoided), each container has its own network namespace. However, ports inside the container can still conflict — for example, if the app image already uses a port that TinyAuth wants. Always check what ports the base image uses internally and choose a non-conflicting port for TinyAuth (default 3001, fallback 3011, etc.).

### Schema and Image Cache
The Supervisor caches addon schema from the built Docker image. When you change `config.yaml`:
1. Remove the old image: `docker rmi -f $(docker images -q --filter 'reference=*my-addon*')`
2. Rebuild: `ha apps rebuild local_my-addon`
3. If schema still stale: `docker restart hassio_supervisor`, wait 20s, then rebuild again
4. If that fails: uninstall + reinstall (loses `/data/` — back up first)

**IMPORTANT:** `scp -r my-addon/ host:/addons/my-addon/` creates `/addons/my-addon/my-addon/` (nested). Use `scp -r my-addon/* host:/addons/my-addon/` instead. A stale subdirectory can cause the Docker build to use the wrong files.

### Docker Build Layer Cache
The `COPY init /init` layer is cached by Docker based on the file checksum. However, if stale copies of init exist in subdirectories (from bad scp), Docker may pick the wrong one. Always verify after rebuild:
```bash
docker exec addon_local_my-addon md5sum /init
```

### Password Fields in UI
Use `password` type in schema to mask sensitive fields in the HA UI:
```yaml
schema:
  my_token: password
  my_secret: password?  # optional password
```

### NPM (Nginx Proxy Manager) Caching
If there's an NPM reverse proxy in front of the addon, it may cache 401 responses aggressively. After fixing auth issues, clear the NPM cache:
```bash
docker exec <npm-container> sh -c 'rm -rf /tmp/nginx/cache/public/*'
```
For apps where caching causes issues, add to the NPM proxy host advanced config:
```nginx
proxy_no_cache 1;
proxy_cache_bypass 1;
```

### PWA / Service Worker
If the app is a PWA, the `service_worker.js` and manifest assets must be served WITHOUT authentication. Create a higher-priority Traefik router for these public paths (see templates).

### Environment Variable Leaking
When using `export VAR=value` in the init script, all subsequent processes inherit it. Be careful with `PORT` — start the main app BEFORE exporting `PORT` for TinyAuth, or the app might pick up TinyAuth's port. If the app uses supervisord internally, its child processes inherit the parent environment at fork time.

### Log Noise Reduction
- Set `GIN_MODE=release` to suppress TinyAuth/Gin debug output
- Redirect stdout to `/dev/null` for each service (`>/dev/null &`) to hide startup banners, but keep stderr for runtime errors
- Set `LOG_LEVEL=warn` for TinyAuth

### Google OAuth Setup
The user needs to configure a Google OAuth consent screen and credentials in GCP Console:
- APIs & Services → Credentials → Create OAuth 2.0 Client ID
- Authorized redirect URI: `https://auth.<host>/api/oauth/callback/google`

### set -e in Subshells
The `set -e` from the main script propagates to subshells (background loops). Any command failure inside a `( ... ) &` subshell kills the entire loop silently. Always add `set +e` at the top of background subshells that should be resilient.

### Git Sync for File-Based Apps
For apps that manage files (wikis, notes, knowledge bases), implement git sync as a background loop. Key patterns:
- **Init order matters:** Clone/checkout the repo BEFORE starting the app, so it finds content on first boot
- **`git config --global --add safe.directory`** is required because the data volume may have different ownership
- **`git config --global init.defaultBranch main`** avoids the `master` default branch warning
- **Git LFS:** If the repo uses LFS, add `git-lfs` to Dockerfile dependencies and run `git lfs install --force` + `git lfs pull` during clone
- **Commit before rebase:** The sync loop must commit local changes BEFORE fetching/rebasing, otherwise dirty working tree causes rebase to fail
- **`set +e` in the loop:** Prevents the background sync from dying on transient errors
- **Silent when idle:** Only log when changes are pushed or errors occur
- **Fatal on init, resilient on sync:** Git init/clone errors should abort the addon; sync loop errors should log and continue
- **Detect existing credentials:** If the git remote URL already contains `@` (embedded token), skip overriding with addon options

See `references/templates-auth.md` for the full git sync template.
