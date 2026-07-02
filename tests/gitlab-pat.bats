#!/usr/bin/env bats
# Regression tests for scripts/gitlab-pat.sh cached-token revalidation.
# The minted PAT expires after 30 days (gitlab-bootstrap.rb), so the cache in
# gitlab/.gitlab-token can hold a revoked/expired token. The script must verify
# the cached token against /api/v4/user before reusing it — serving a dead
# token broke `make up` at gitlab-configure (401 invalid_token).
# Clusterless: curl and docker are stubbed on PATH.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK/gitlab" "$WORK/scripts" "$BATS_TEST_TMPDIR/bin"
  cp "$REPO/scripts/gitlab-pat.sh" "$WORK/scripts/"
  cp "$REPO/scripts/gitlab-bootstrap.rb" "$WORK/scripts/"
  echo "GITLAB_ROOT_PASSWORD=stub-pw" > "$WORK/gitlab/.env"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

  # docker stub: cp is a no-op; exec "mints" a fresh token
  cat > "$BATS_TEST_TMPDIR/bin/docker" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  cp) exit 0 ;;
  exec) echo "glpat-freshly-minted-token" ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/docker"
}

# curl stub emitting a fixed HTTP code via -w (mirrors real curl -o /dev/null)
stub_curl() {
  local code="$1" rc="${2:-0}"
  cat > "$BATS_TEST_TMPDIR/bin/curl" <<EOF
#!/usr/bin/env bash
printf '%s' "$code"
exit $rc
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/curl"
}

@test "valid cached token (200) is reused, not re-minted" {
  echo "glpat-cached-valid" > "$WORK/gitlab/.gitlab-token"
  stub_curl 200
  run bash "$WORK/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "glpat-cached-valid" ]
  [ "$(cat "$WORK/gitlab/.gitlab-token")" = "glpat-cached-valid" ]
}

@test "revoked cached token (401) is discarded and a fresh one minted" {
  echo "glpat-cached-revoked" > "$WORK/gitlab/.gitlab-token"
  stub_curl 401 22
  run bash "$WORK/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"glpat-freshly-minted-token"* ]]
  [[ "$output" != *"glpat-cached-revoked"* ]]
  [ "$(cat "$WORK/gitlab/.gitlab-token")" = "glpat-freshly-minted-token" ]
}

@test "forbidden cached token (403) is discarded and a fresh one minted" {
  echo "glpat-cached-forbidden" > "$WORK/gitlab/.gitlab-token"
  stub_curl 403 22
  run bash "$WORK/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$WORK/gitlab/.gitlab-token")" = "glpat-freshly-minted-token" ]
}

@test "GitLab unreachable (000) keeps and prints the cached token" {
  echo "glpat-cached-offline" > "$WORK/gitlab/.gitlab-token"
  stub_curl 000 7
  run bash "$WORK/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "glpat-cached-offline" ]
  [ "$(cat "$WORK/gitlab/.gitlab-token")" = "glpat-cached-offline" ]
}

@test "no cached token mints a fresh one" {
  rm -f "$WORK/gitlab/.gitlab-token"
  stub_curl 200
  run bash "$WORK/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"glpat-freshly-minted-token"* ]]
}

@test "gitlab-pat.sh validates the cached token against /api/v4/user" {
  run grep -c 'api/v4/user' "$REPO/scripts/gitlab-pat.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
