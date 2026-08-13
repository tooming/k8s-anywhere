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

# `docker exec` connects as the image's raw default user (root) — it does not
# inherit the entrypoint's own privilege-drop to USER_UID/USER_GID (that only
# happens for the container's PID 1 process, via the s6-init supervisor exec'ing
# forgejo as the unprivileged user after root-only setup steps). Forgejo's own CLI
# refuses to run as root ("Forgejo is not supposed to be run as root" — found live
# 2026-08-13, first `make forgejo-up`). Force the exec onto the same UID/GID the
# compose file's USER_UID/USER_GID env vars configure (1000:1000), the documented
# fix for this exact class of Gitea/Forgejo `docker exec` issue.
#
# Also found live: without an explicit --config, the CLI can't locate app.ini from
# a bare `docker exec` (it isn't run through the entrypoint that normally sets
# GITEA_WORK_DIR) and fails with "Unable to load config file for a installed
# Forgejo instance". Confirmed the real in-container path directly
# (`docker exec forgejo find / -iname app.ini`): /data/gitea/conf/app.ini.
# --config is an `admin`-level flag (`forgejo admin --help`), not a `user
# create`-level one — it must come before the `user` subcommand or the CLI parses
# it as an unrecognized flag to `user create` and silently falls back to no config.
if docker exec -u 1000:1000 forgejo forgejo admin --config /data/gitea/conf/app.ini \
     user create \
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
