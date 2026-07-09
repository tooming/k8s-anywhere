#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# capstone-pipeline namespace (ADR-0017 §Per-namespace profile,
# ROADMAP auto/capstone-pipeline-psa).
# No workloads currently run in capstone-pipeline (Kargo itself runs in the
# kargo namespace; the Project CRD manages this namespace). The restricted
# floor is defense-in-depth — any future pod admitted here is hardened by default.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/kargo-project/namespace.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "capstone-pipeline namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "capstone-pipeline namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace does not enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

@test "capstone-pipeline namespace does not enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- kargo-project Application sources the kargo-project directory -----------

@test "kargo-project Application sources gitops/kargo-project path" {
  run grep -q 'path: gitops/kargo-project' "$REPO/gitops/platform/kargo-project.yaml"
  [ "$status" -eq 0 ]
}
