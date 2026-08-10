#!/usr/bin/env bash
# Idempotently create the Forgejo lab-admin user once the container is healthy.
# Forgejo has no compose-time "initial root password" env var the way GitLab's
# omnibus config does (see forgejo-env-ensure.sh's comment) — admin creation is a
# post-boot CLI step. `forgejo admin user create` exits non-zero if the user already
# exists, so this is safe to call on every `make forgejo-up`.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_FILE="$ROOT/forgejo/.env"

pw="$(grep -E '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"
if [ -z "$pw" ]; then
  echo "forgejo-admin-ensure: FORGEJO_ADMIN_PASSWORD missing from forgejo/.env — run forgejo-env-ensure.sh first" >&2
  exit 1
fi

if docker exec forgejo forgejo admin user create \
     --admin --username lab-admin --email lab-admin@localhost \
     --password "$pw" --must-change-password=false >/tmp/forgejo-admin-ensure.out 2>&1; then
  echo "  ok  created Forgejo admin user 'lab-admin'"
elif grep -qi "already exists" /tmp/forgejo-admin-ensure.out; then
  echo "  ok  Forgejo admin user 'lab-admin' already exists"
else
  echo "  ·   forgejo admin user create failed:" >&2
  cat /tmp/forgejo-admin-ensure.out >&2
  exit 1
fi
