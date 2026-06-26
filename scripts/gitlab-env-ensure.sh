#!/usr/bin/env bash
# Ensure gitlab/.env exists with a GITLAB_ROOT_PASSWORD before `docker compose up`.
#
# gitlab/.env is gitignored (it holds a secret), so a fresh clone — or any machine
# that lost the file — has no .env, and `make gitlab-up` dies immediately on compose
# interpolation:
#   required variable GITLAB_ROOT_PASSWORD is missing a value: set it in gitlab/.env
# That broke `make up` end-to-end. Nothing in the bootstrap ever (re)created the file.
#
# This makes the step self-healing (idempotent): if a non-empty GITLAB_ROOT_PASSWORD
# is already present, it's a no-op. Otherwise it generates a strong password, writes
# gitlab/.env (mode 600), and — if GitLab is ALREADY running (so its root password was
# set on a now-lost .env) — resets the live root password to match, keeping `make creds`
# truthful (ADR-0004). On a fresh machine GitLab isn't up yet, so first boot just
# consumes initial_root_password from the new .env; the values stay consistent.
#
# Wired as the first line of `make gitlab-up`, so gitlab-up can't run without it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_FILE="$ROOT/gitlab/.env"

cur=""
[ -f "$ENV_FILE" ] && cur="$(grep -E '^GITLAB_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"

if [ -n "$cur" ]; then
  echo "  ok  gitlab/.env already has GITLAB_ROOT_PASSWORD"
  exit 0
fi

# hex + a fixed "Lab-" prefix → satisfies GitLab's length/complexity rules and is free
# of characters that need escaping in a .env value, a shell, or a Ruby string.
pw="Lab-$(openssl rand -hex 16)"

umask 177  # 0600
if [ -f "$ENV_FILE" ] && ! grep -qE '^GITLAB_ROOT_PASSWORD=' "$ENV_FILE"; then
  printf 'GITLAB_ROOT_PASSWORD=%s\n' "$pw" >> "$ENV_FILE"
else
  printf 'GITLAB_ROOT_PASSWORD=%s\n' "$pw" > "$ENV_FILE"
fi
chmod 600 "$ENV_FILE"
echo "  ok  wrote gitlab/.env with a freshly generated GITLAB_ROOT_PASSWORD"

# If GitLab is already running, its root password was set from a now-lost .env, so the
# generated value wouldn't match. Reset the live root password to it (safe, idempotent;
# tokens/deploy-keys are unaffected) so make creds shows a password that actually works.
if docker inspect -f '{{.State.Running}}' gitlab >/dev/null 2>&1 \
   && [ "$(docker inspect -f '{{.State.Running}}' gitlab 2>/dev/null)" = "true" ]; then
  echo "  ·   GitLab is already running — resetting live root password to match the new .env"
  if docker exec -e PW="$pw" gitlab gitlab-rails runner '
        u = User.find_by_username("root")
        if u
          u.password = ENV["PW"]; u.password_confirmation = ENV["PW"]
          u.password_expires_at = nil
          u.save!
          STDERR.puts "root password reset"
        end' >/dev/null 2>&1; then
    echo "  ok  live root password reset to match gitlab/.env"
  else
    echo "  ·   could not reset live root password (GitLab still initialising?) — first reconfigure will pick up the new .env" >&2
  fi
fi
