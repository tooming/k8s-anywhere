#!/usr/bin/env bash
# Ensure forgejo/.env exists with a FORGEJO_ADMIN_PASSWORD before creating the admin
# user. Mirrors scripts/gitlab-env-ensure.sh's self-healing pattern (ADR-0035's
# migration keeps the same operational shape GitLab had) — but Forgejo, unlike
# GitLab's omnibus GITLAB_OMNIBUS_CONFIG, has no compose-time env var that sets an
# initial admin password: the admin user is created post-boot via `forgejo admin user
# create` (see scripts/forgejo-admin-ensure.sh), so forgejo/.env only needs to exist
# before THAT step runs, not before `docker compose up` itself.
#
# forgejo/.env is gitignored (it holds a secret) — a fresh clone has no .env, so this
# generates one deterministically rather than leaving `make forgejo-up` to fail on a
# missing credential the way a lost gitlab/.env used to (see the gitlab-env-ensure.sh
# comment this mirrors).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_FILE="$ROOT/forgejo/.env"

cur=""
[ -f "$ENV_FILE" ] && cur="$(grep -E '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"

if [ -n "$cur" ]; then
  echo "  ok  forgejo/.env already has FORGEJO_ADMIN_PASSWORD"
  exit 0
fi

# hex + a fixed "Lab-" prefix — same convention as gitlab-env-ensure.sh's password
# shape, free of characters that need escaping in a .env value or a shell arg.
pw="Lab-$(openssl rand -hex 16)"

umask 177  # 0600
if [ -f "$ENV_FILE" ] && ! grep -qE '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE"; then
  printf 'FORGEJO_ADMIN_PASSWORD=%s\n' "$pw" >> "$ENV_FILE"
else
  printf 'FORGEJO_ADMIN_PASSWORD=%s\n' "$pw" > "$ENV_FILE"
fi
chmod 600 "$ENV_FILE"
echo "  ok  wrote forgejo/.env with a freshly generated FORGEJO_ADMIN_PASSWORD"
