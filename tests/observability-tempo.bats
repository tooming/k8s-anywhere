#!/usr/bin/env bats
# Clusterless structural tests for the Tempo image tag pin
# (gitops/observability/tempo/deployment.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOYMENT="$REPO/gitops/observability/tempo/deployment.yaml"
}

@test "tempo deployment pins image tag 2.10.7" {
  run grep -q 'image: grafana/tempo:2.10.7' "$DEPLOYMENT"
  [ "$status" -eq 0 ]
}
