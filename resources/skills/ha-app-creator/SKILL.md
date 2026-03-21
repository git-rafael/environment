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
5. **App-specific options?** Any environment variables the user wants configurable from the HA UI.

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

### Step 5: Deploy and Test

Deploy to the HA server:

```bash
# Copy files to the addons directory
scp -r my-addon/* root@<ha-host>:/addons/my-addon/

# Reload the addon store so Supervisor picks up the new addon
curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/store/reload

# Install (first time) or rebuild (updates)
ha apps install local_my-addon
# or
ha apps rebuild local_my-addon

# Set options via API (needed when schema changes)
curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  http://supervisor/addons/local_my-addon/options \
  -d '{"options":{...}}'

# Start and check logs
ha apps start local_my-addon
ha apps logs local_my-addon
```

## Key Lessons and Gotchas

### HA Supervisor and PID 1
The HA Supervisor injects `--init` (tini as PID 1) regardless of `init: false` in config.yaml. This breaks s6-overlay which requires being PID 1. The solution is a custom bash `/init` entrypoint that starts services as background processes and uses `wait -n` to monitor them.

### Port Conflicts
Without `host_network: true` (which should be avoided), each container has its own network namespace. However, ports inside the container can still conflict — for example, if the app image already uses a port that TinyAuth wants. Always check what ports the base image uses internally and choose a non-conflicting port for TinyAuth (default 3001, fallback 3011, etc.).

### Schema Changes Require Reinstall
When you change the options schema in `config.yaml`, the Supervisor caches the old schema. A rebuild alone won't pick up schema changes. You must:
1. Uninstall: `ha apps uninstall local_my-addon`
2. Reinstall: `ha apps install local_my-addon`
3. Set options via Supervisor API
4. Start: `ha apps start local_my-addon`

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
