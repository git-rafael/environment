# Templates: Addon WITH Authentication (Traefik + TinyAuth)

Use these templates when the user wants Google OAuth authentication in front of their app.

## config.yaml

```yaml
name: "{{APP_NAME}}"
description: "{{APP_DESCRIPTION}}"
version: "0.1.0"
slug: "{{APP_SLUG}}"
url: "{{APP_URL}}"
arch:
  - amd64
  - aarch64
ports:
  {{TRAEFIK_PORT}}/tcp: {{TRAEFIK_PORT}}
ports_description:
  {{TRAEFIK_PORT}}/tcp: "HTTP (main entry)"
map:
  - share:rw
  - ssl:ro
startup: application
init: false
options:
  app_description: "{{DEFAULT_APP_DESCRIPTION}}"
  host: "{{DEFAULT_HOST}}"
  oauth_whitelist: "{{DEFAULT_EMAIL}}"
  google_client_id: ""
  google_client_secret: ""
schema:
  app_description: str
  host: str
  oauth_whitelist: str
  google_client_id: str
  google_client_secret: str
```

Add app-specific options to both `options` and `schema` sections as needed.

## build.yaml (Only for Strategy A — HA base image)

```yaml
build_from:
  amd64: ghcr.io/home-assistant/amd64-base:3.20
  aarch64: ghcr.io/home-assistant/aarch64-base:3.20
```

## Dockerfile — Strategy A (HA base image)

```dockerfile
ARG BUILD_FROM

FROM ${BUILD_FROM}

# --- System dependencies ---
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    jq

# --- App binary ---
COPY --from={{APP_IMAGE}} {{APP_BINARY_SRC}} {{APP_BINARY_DEST}}

# --- Traefik binary (reusable) ---
COPY --from=ghcr.io/traefik/traefik:v3.3 /usr/local/bin/traefik /usr/local/bin/traefik

# --- TinyAuth binary (reusable) ---
COPY --from=ghcr.io/steveiliop56/tinyauth:v4 /tinyauth/tinyauth /usr/local/bin/tinyauth
RUN mkdir -p /data/tinyauth

# --- Custom entrypoint ---
COPY init /init
RUN chmod +x /init
```

## Dockerfile — Strategy B (App image as base)

```dockerfile
FROM {{APP_IMAGE}}

# --- System dependencies (Debian/Ubuntu) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    && rm -rf /var/lib/apt/lists/*

# For Alpine-based images, use instead:
# RUN apk add --no-cache jq

# --- Traefik binary (reusable) ---
COPY --from=ghcr.io/traefik/traefik:v3.3 /usr/local/bin/traefik /usr/local/bin/traefik

# --- TinyAuth binary (reusable) ---
COPY --from=ghcr.io/steveiliop56/tinyauth:v4 /tinyauth/tinyauth /usr/local/bin/tinyauth
RUN mkdir -p /data/tinyauth

# --- Custom entrypoint ---
COPY init /init
RUN chmod +x /init
CMD ["/init"]
```

The `CMD ["/init"]` is critical for Strategy B — it overrides the app image's default CMD/ENTRYPOINT. Strategy A doesn't need it because HA base images have no default CMD.

## init script

```bash
#!/usr/bin/env bash
# Custom entrypoint for HA addon.
# Starts the app, Traefik and TinyAuth as background processes and waits.

set -e

# ---------------------------------------------------------------
# Source options from HA
# ---------------------------------------------------------------
OPTIONS="/data/options.json"

# ---------------------------------------------------------------
# Traefik config generation
# ---------------------------------------------------------------
TRAEFIK_HOST=$(jq -r '.host' "$OPTIONS")
TINYAUTH_HOST="auth.${TRAEFIK_HOST}"
TINYAUTH_APP_URL="https://${TINYAUTH_HOST}"

mkdir -p /etc/traefik

cat > /etc/traefik/traefik.yml <<TRAEFIK_STATIC
api:
  dashboard: false
entryPoints:
  web:
    address: ":{{TRAEFIK_PORT}}"
providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true
TRAEFIK_STATIC

cat > /etc/traefik/dynamic.yml <<TRAEFIK_DYNAMIC
http:
  routers:
    {{APP_SLUG}}:
      rule: "Host(\`${TRAEFIK_HOST}\`)"
      entryPoints:
        - web
      middlewares:
        - tinyauth
      service: {{APP_SLUG}}
    tinyauth-ui:
      rule: "Host(\`${TINYAUTH_HOST}\`)"
      entryPoints:
        - web
      service: tinyauth
  middlewares:
    tinyauth:
      forwardAuth:
        address: "http://127.0.0.1:{{TINYAUTH_PORT}}/api/auth/traefik"
        trustForwardHeader: true
        authResponseHeaders:
          - Remote-User
          - Remote-Groups
          - Remote-Name
          - Remote-Email
  services:
    {{APP_SLUG}}:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:{{APP_INTERNAL_PORT}}"
    tinyauth:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:{{TINYAUTH_PORT}}"
TRAEFIK_DYNAMIC

echo "[init] Traefik config generated."

# ---------------------------------------------------------------
# App
# ---------------------------------------------------------------
# TODO: Set app-specific environment variables here
# TODO: Create persistent data directories under /data/
# TODO: Symlink any non-/data/ paths the app uses:
#   mkdir -p /data/myapp-db
#   rm -rf /original/path
#   ln -s /data/myapp-db /original/path

echo "[init] Starting {{APP_NAME}}..."
{{APP_START_COMMAND}} >/dev/null &
APP_PID=$!

# ---------------------------------------------------------------
# TinyAuth
# ---------------------------------------------------------------
export PORT={{TINYAUTH_PORT}}
export DATABASE_PATH=/data/tinyauth/tinyauth.db
export RESOURCES_PATH=/data/tinyauth/resources
export LOG_LEVEL=warn
export DISABLE_UI_WARNINGS=true
export DISABLE_ANALYTICS=true
export GIN_MODE=release
export APP_URL="${TINYAUTH_APP_URL}"
export APP_TITLE=$(jq -r '.app_description' "$OPTIONS")
export OAUTH_AUTO_REDIRECT="google"
export OAUTH_WHITELIST=$(jq -r '.oauth_whitelist' "$OPTIONS")
export PROVIDERS_GOOGLE_CLIENT_ID=$(jq -r '.google_client_id' "$OPTIONS")
export PROVIDERS_GOOGLE_CLIENT_SECRET=$(jq -r '.google_client_secret' "$OPTIONS")

mkdir -p /data/tinyauth/resources

echo "[init] Starting TinyAuth..."
/usr/local/bin/tinyauth >/dev/null &
TINYAUTH_PID=$!

# ---------------------------------------------------------------
# Traefik
# ---------------------------------------------------------------
echo "[init] Starting Traefik..."
/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml >/dev/null &
TRAEFIK_PID=$!

# ---------------------------------------------------------------
# Wait for any process to exit, then stop all
# ---------------------------------------------------------------
echo "[init] All services started."

CORE_PIDS="$APP_PID $TINYAUTH_PID $TRAEFIK_PID"

wait -n $CORE_PIDS 2>/dev/null || true

echo "[init] A core service exited. Shutting down..."
kill $CORE_PIDS 2>/dev/null || true
wait
exit 1
```

## Template Variables

| Variable | Description | Example |
|---|---|---|
| `{{APP_NAME}}` | Display name | `SilverBullet` |
| `{{APP_SLUG}}` | URL-safe identifier | `silverbullet` |
| `{{APP_DESCRIPTION}}` | Short description | `Personal knowledge base with auth` |
| `{{APP_URL}}` | Project homepage | `https://github.com/org/app` |
| `{{APP_IMAGE}}` | Docker image | `ghcr.io/org/app:latest` |
| `{{TRAEFIK_PORT}}` | External Traefik port | `5002` |
| `{{TINYAUTH_PORT}}` | Internal TinyAuth port | `3001` |
| `{{APP_INTERNAL_PORT}}` | Internal app port | `3000` |
| `{{APP_START_COMMAND}}` | Command to start app | `/app/server` |
| `{{DEFAULT_HOST}}` | Default hostname | `app.example.com` |
| `{{DEFAULT_EMAIL}}` | Default OAuth email | `user@example.com` |

## Advanced Routing Patterns

### PWA / Service Worker (public assets without auth)

Add a higher-priority router for public static assets:

```yaml
routers:
  {{APP_SLUG}}-public:
    rule: "Host(`${TRAEFIK_HOST}`) && (Path(`/service_worker.js`) || PathPrefix(`/.client/`))"
    entryPoints:
      - web
    service: {{APP_SLUG}}
    priority: 20
  {{APP_SLUG}}:
    rule: "Host(`${TRAEFIK_HOST}`)"
    # ... rest with tinyauth middleware
    priority: 10
```

### Separate API backend (different internal port)

When the frontend and API run on different ports (e.g., Next.js frontend on 8502, API on 5055):

```yaml
routers:
  {{APP_SLUG}}-api:
    rule: "Host(`${TRAEFIK_HOST}`) && PathPrefix(`/api`)"
    entryPoints:
      - web
    middlewares:
      - tinyauth
    service: {{APP_SLUG}}-api
    priority: 20
  {{APP_SLUG}}:
    rule: "Host(`${TRAEFIK_HOST}`)"
    entryPoints:
      - web
    middlewares:
      - tinyauth
    service: {{APP_SLUG}}
    priority: 10
services:
  {{APP_SLUG}}-api:
    loadBalancer:
      servers:
        - url: "http://127.0.0.1:{{API_PORT}}"
  {{APP_SLUG}}:
    loadBalancer:
      servers:
        - url: "http://127.0.0.1:{{FRONTEND_PORT}}"
```

This is needed when the frontend does client-side API calls and auto-detects the API URL by appending a port to the current hostname. Setting `API_URL` to the public HTTPS URL (`https://${TRAEFIK_HOST}`) and routing `/api` directly to the API backend avoids this.
