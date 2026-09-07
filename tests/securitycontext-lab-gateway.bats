#!/usr/bin/env bats
# Clusterless structural tests for PSS-restricted fan-out to the lab-gateway
# namespace (ADR-0017 §Staged rollout, CHARTER Objective O2). Split out of
# tests/securitycontext-moto-ack-labgateway.bats when moto/ACK/KRO were removed
# entirely 2026-09-07 (ADR-0038, no replacement) — lab-gateway itself is
# unrelated to that trio (it's the shared Traefik/TLSStore namespace) and still
# needs its own coverage per the O2 recurrence guard in tests/drift-detectors.bats.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  GW_NS="$REPO/gitops/network/namespace.yaml"
}

# --- lab-gateway namespace PSA labels ----------------------------------------

@test "lab-gateway namespace.yaml exists" {
  [ -f "$GW_NS" ]
}

@test "lab-gateway namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}
