#!/usr/bin/env bats
# Structural tests for the two imperative bootstrap seams wired into `make up`
# (ADR-0006): gitlab-tls-bootstrap and grafana-gitsync-bootstrap.
# All checks are clusterless — they assert code structure and Makefile wiring.

setup() { REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

# --- scripts present and executable ------------------------------------------
@test "gitlab-tls-bootstrap.sh exists and is executable" {
  [ -x "$REPO/scripts/gitlab-tls-bootstrap.sh" ]
}

@test "grafana-gitsync-bootstrap.sh exists and is executable" {
  [ -x "$REPO/scripts/grafana-gitsync-bootstrap.sh" ]
}

# --- make up wires both bootstraps -------------------------------------------
@test "make up calls gitlab-tls-bootstrap" {
  run grep -n 'gitlab-tls-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  # Must appear in the 'up' recipe (not only as a standalone target header)
  [[ "$output" == *"MAKE) gitlab-tls-bootstrap"* ]]
}

@test "make up calls grafana-gitsync-bootstrap" {
  run grep -n 'grafana-gitsync-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAKE) grafana-gitsync-bootstrap"* ]]
}

@test "make up calls gitlab-tls-bootstrap before grafana-gitsync-bootstrap" {
  tls_line=$(grep -n 'MAKE) gitlab-tls-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  gs_line=$(grep -n 'MAKE) grafana-gitsync-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  [ -n "$tls_line" ] && [ -n "$gs_line" ]
  [ "$tls_line" -lt "$gs_line" ]
}

@test "make up calls gitlab-tls-bootstrap after vault-bootstrap" {
  vault_line=$(grep -n 'MAKE) vault-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  tls_line=$(grep -n 'MAKE) gitlab-tls-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  [ -n "$vault_line" ] && [ -n "$tls_line" ]
  [ "$vault_line" -lt "$tls_line" ]
}

# --- gitlab-tls-bootstrap has Grafana restart logic --------------------------
@test "gitlab-tls-bootstrap.sh rolls Grafana deployment when it is already running" {
  run grep -c 'rollout restart deployment/grafana' "$REPO/scripts/gitlab-tls-bootstrap.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# --- grafana-gitsync-bootstrap has a health wait loop ------------------------
@test "grafana-gitsync-bootstrap.sh waits for Grafana /api/health before calling the API" {
  run grep -c '/api/health' "$REPO/scripts/grafana-gitsync-bootstrap.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# --- DR.md documents both new steps ------------------------------------------
@test "DR.md documents gitlab-tls-bootstrap in the bootstrap order table" {
  run grep -c 'gitlab-tls-bootstrap' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "DR.md documents grafana-gitsync-bootstrap in the bootstrap order table" {
  run grep -c 'grafana-gitsync-bootstrap' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
