#!/usr/bin/env bash
# Ensure a root admin exists in GitLab and mint (or reuse) an api-scoped PAT for the
# Terraform gitlab provider. Uses a ruby script via gitlab-rails runner (no API
# chicken-and-egg). Token cached in gitlab/.gitlab-token (gitignored). Prints token.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TOKEN_FILE="$ROOT/gitlab/.gitlab-token"

if [ -s "$TOKEN_FILE" ]; then
  cat "$TOKEN_FILE"
  exit 0
fi

PW="$(grep -E '^GITLAB_ROOT_PASSWORD=' "$ROOT/gitlab/.env" | cut -d= -f2-)"

docker cp "$HERE/gitlab-bootstrap.rb" gitlab:/tmp/gitlab-bootstrap.rb >/dev/null
tok="$(docker exec -e PW="$PW" gitlab gitlab-rails runner /tmp/gitlab-bootstrap.rb 2>/dev/null | grep -oE 'glpat-[A-Za-z0-9_.-]+' | head -1)"

if [ -z "${tok:-}" ]; then
  echo "ERROR: failed to mint GitLab token (is GitLab healthy?)" >&2
  exit 1
fi

printf '%s\n' "$tok" > "$TOKEN_FILE"
printf '%s\n' "$tok"
