#!/usr/bin/env bats
# Clusterless structural tests for the External Secrets Operator chart pin
# (gitops/platform/external-secrets.yaml). Per-scope file, mirrors the
# repo's other exact-version-pin test pairs (e.g. tests/observability-loki.bats,
# tests/trivy-operator.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/external-secrets.yaml"
}

@test "external-secrets Application pins chart targetRevision 2.9.0" {
  run grep -q 'targetRevision: 2.9.0' "$APP"
  [ "$status" -eq 0 ]
}

@test "external-secrets Application does not pin the stale 2.8.0 chart" {
  run grep -q 'targetRevision: 2.8.0' "$APP"
  [ "$status" -ne 0 ]
}
