#!/usr/bin/env bats
# Clusterless structural tests for the Pyroscope chart pin
# (gitops/platform/observability-pyroscope.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/observability-pyroscope.yaml"
}

@test "pyroscope Application pins chart targetRevision 2.2.1" {
  run grep -q 'targetRevision: 2.2.1' "$APP"
  [ "$status" -eq 0 ]
}

@test "pyroscope Application does not pin the stale 2.2.0 chart" {
  run grep -q 'targetRevision: 2.2.0' "$APP"
  [ "$status" -ne 0 ]
}
