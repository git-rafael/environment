# Templates: Addon WITHOUT Authentication

Use these templates when the user does not need authentication — the app is exposed directly.

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
  {{APP_PORT}}/tcp: {{APP_PORT}}
ports_description:
  {{APP_PORT}}/tcp: "{{APP_NAME}} HTTP"
map:
  - share:rw
startup: application
init: false
options: {}
schema: {}
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
    jq

# --- App binary ---
COPY --from={{APP_IMAGE}} {{APP_BINARY_SRC}} {{APP_BINARY_DEST}}

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

# --- Custom entrypoint ---
COPY init /init
RUN chmod +x /init
CMD ["/init"]
```

## init script

```bash
#!/usr/bin/env bash
set -e

OPTIONS="/data/options.json"

# ---------------------------------------------------------------
# App
# ---------------------------------------------------------------
# TODO: Set app-specific environment variables here
# TODO: Create persistent data directories under /data/
# TODO: Symlink any non-/data/ paths the app uses

echo "[init] Starting {{APP_NAME}}..."
{{APP_START_COMMAND}} >/dev/null &
APP_PID=$!

# ---------------------------------------------------------------
# Wait for process to exit
# ---------------------------------------------------------------
echo "[init] All services started."

wait $APP_PID 2>/dev/null || true

echo "[init] App exited. Shutting down..."
exit 1
```
