#!/usr/bin/env bats
# Clusterless structural tests for the PSS *privileged* profile applied to the
# istio-system namespace (ADR-0017 §Per-namespace profile, ADR-0012 §PSA profile,
# ROADMAP auto/pss-np-istio-system).
# privileged (not restricted or baseline) because istio-cni mutates the host CNI
# config and ztunnel requires NET_ADMIN — both fail under restricted/baseline.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith caused recurring merge conflicts
# (#238 vs #239). One scope = one file = no shared append anchor.
# Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/istio-system/namespace.yaml"
}

# --- namespace PSA privileged labels -----------------------------------------

@test "istio-system namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "istio-system namespace enforces PSS privileged" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "istio-system namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "istio-system namespace has warn: privileged" {
  run grep -q 'pod-security.kubernetes.io/warn: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "istio-system namespace has audit: privileged" {
  run grep -q 'pod-security.kubernetes.io/audit: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "istio-system namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 1 ]
}

@test "istio-system namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 1 ]
}

# --- istio-system-extras Application -----------------------------------------

@test "gitops/platform/istio-system-extras.yaml exists" {
  [ -f "$REPO/gitops/platform/istio-system-extras.yaml" ]
}

@test "istio-system-extras Application targets gitops/istio-system path" {
  run grep -q 'path: gitops/istio-system' "$REPO/gitops/platform/istio-system-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$REPO/gitops/platform/istio-system-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system-extras Application is auto-synced" {
  run grep -q 'automated:' "$REPO/gitops/platform/istio-system-extras.yaml"
  [ "$status" -eq 0 ]
}
