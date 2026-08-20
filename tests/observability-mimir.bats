#!/usr/bin/env bats
# Clusterless structural tests for the Mimir image tag pin
# (gitops/observability/mimir/deployment.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOYMENT="$REPO/gitops/observability/mimir/deployment.yaml"
}

@test "mimir deployment pins image tag 3.1.5" {
  run grep -q 'image: grafana/mimir:3.1.5' "$DEPLOYMENT"
  [ "$status" -eq 0 ]
}

@test "mimir deployment does not pin the stale 3.1.4 tag" {
  run grep -q 'image: grafana/mimir:3.1.4' "$DEPLOYMENT"
  [ "$status" -ne 0 ]
}
