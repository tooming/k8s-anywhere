#!/usr/bin/env bats
# Clusterless structural tests for the Loki image tag pin
# (gitops/observability/loki/deployment.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOYMENT="$REPO/gitops/observability/loki/deployment.yaml"
}

@test "loki deployment pins image tag 3.7.6" {
  run grep -q 'image: grafana/loki:3.7.6' "$DEPLOYMENT"
  [ "$status" -eq 0 ]
}

@test "loki deployment does not pin the stale 3.7.5 tag" {
  run grep -q 'image: grafana/loki:3.7.5' "$DEPLOYMENT"
  [ "$status" -ne 0 ]
}
