#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# argo-rollouts namespace (ADR-0017 §Per-namespace profile, ADR-0020,
# ROADMAP auto/argo-rollouts-controller). restricted because the Argo Rollouts
# controller and dashboard run as non-root; no host volumes or special capabilities.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/argo-rollouts/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/argo-rollouts-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "argo-rollouts namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "argo-rollouts namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

@test "argo-rollouts namespace does NOT enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- argo-rollouts-extras Application ----------------------------------------

@test "argo-rollouts-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "argo-rollouts-extras Application targets gitops/argo-rollouts" {
  run grep -q 'path: gitops/argo-rollouts' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}
