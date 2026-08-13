#!/usr/bin/env bash
# Idempotently register the Forgejo Actions runner and (re)start it in daemon mode.
#
# The runner image ships no entrypoint script and no default CMD — without a real
# registration (a `.runner` file derived from a live registration token) `daemon`
# refuses to start. Registration must happen exactly once per Forgejo instance
# lifetime (a fresh `make forgejo-up` after `docker compose down -v` needs this to
# run again — the token is instance-specific and dies with the instance's DB).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
RUNNER_DIR="$ROOT/forgejo/runner-config"
CONFIG="$RUNNER_DIR/config.yml"
RUNNER_STATE="$RUNNER_DIR/.runner"
ENV_FILE="$ROOT/forgejo/.env"

if [ -f "$RUNNER_STATE" ]; then
  echo "  ok  Forgejo runner already registered (found $RUNNER_STATE)"
else
  pw="$(grep -E '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"
  if [ -z "$pw" ]; then
    echo "forgejo-runner-ensure: FORGEJO_ADMIN_PASSWORD missing from forgejo/.env — run forgejo-env-ensure.sh first" >&2
    exit 1
  fi

  mkdir -p "$RUNNER_DIR"
  if [ ! -f "$CONFIG" ]; then
    docker run --rm code.forgejo.org/forgejo/runner:13.0.0 forgejo-runner generate-config > "$CONFIG"
  fi

  # GET, not POST (found live 2026-08-13: POST returns 405 Method Not Allowed).
  token="$(curl -sf -m 15 -X GET -u "lab-admin:${pw}" \
    http://localhost:3300/api/v1/admin/runners/registration-token \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')"
  if [ -z "$token" ]; then
    echo "forgejo-runner-ensure: failed to fetch a runner registration token from the API" >&2
    exit 1
  fi

  # A one-off container, not `docker exec forgejo-runner` — the compose service's
  # own container crash-restart-loops until it's registered (its `command:` is
  # `daemon`, which needs the registration this step produces), so exec'ing into
  # it races the restart. `register` is soft-deprecated (a runtime warning, not a
  # removed command) but is still the documented way to produce a `.runner` file.
  docker run --rm --network forgejo_default \
    -v "$RUNNER_DIR:/data" \
    code.forgejo.org/forgejo/runner:13.0.0 \
    forgejo-runner register --no-interactive \
    --instance http://forgejo:3000 \
    --token "$token" \
    --name lab-forgejo-runner \
    --labels "docker:docker://node:20-bookworm,ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-latest" \
    --config /data/config.yml

  echo "  ok  registered Forgejo runner 'lab-forgejo-runner'"
fi

# Restart (not just start) — if the container was already crash-looping on the
# unregistered state, compose's own restart backoff can leave it down for a while;
# force an immediate fresh attempt now that registration exists.
(cd "$ROOT/forgejo" && docker compose up -d --force-recreate forgejo-runner)
