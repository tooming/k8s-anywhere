#!/usr/bin/env bash
# Ensure a root admin exists in GitLab and mint (or reuse) an api-scoped PAT for the
# Terraform gitlab provider. Uses a ruby script via gitlab-rails runner (no API
# chicken-and-egg). Token cached in gitlab/.gitlab-token (gitignored). Prints token.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TOKEN_FILE="$ROOT/gitlab/.gitlab-token"
GITLAB_URL="${GITLAB_URL:-http://localhost:8929}"

# The minted PAT expires after 30 days (gitlab-bootstrap.rb), so a cached token
# can be dead while the file looks fine. Verify it against the API before reuse;
# only a definitive 401/403 discards the cache — if GitLab is unreachable we
# keep the old behavior (print the cache) so offline callers aren't broken.
if [ -s "$TOKEN_FILE" ]; then
  tok="$(cat "$TOKEN_FILE")"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    --header "PRIVATE-TOKEN: $tok" "$GITLAB_URL/api/v4/user" || true)"
  case "$code" in
    401|403)
      echo "gitlab-pat: cached token rejected (HTTP $code) — re-minting" >&2
      rm -f "$TOKEN_FILE"
      ;;
    *)
      printf '%s\n' "$tok"
      exit 0
      ;;
  esac
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
