#!/usr/bin/env bats
# Clusterless structural tests for Pod Security Standards hardening (ADR-0017, RFC #83).
# Asserts the capstone pilot Deployment and Namespace manifest carry all required
# PSS restricted fields without spinning up a cluster.
#
# FROZEN — do NOT add new @test blocks here. Two parallel PSS fan-out PRs appending a
# per-namespace block to this file's EOF is what caused the recurring merge conflict
# (#238 vs #239). New per-namespace / per-scope security-context tests go in their own
# tests/securitycontext-<scope>.bats file (see -argocd, -lab-gateway).
# This freeze is enforced mechanically by scripts/securitycontext-tests-check.sh (make ci);
# if you intentionally rename/edit an existing test here, run `make securitycontext-tests-mark`.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
}

# --- baseline carve-out namespaces (ADR-0017 §Per-namespace profile) ----------
# (storage/Garage's PSS-baseline row was removed 2026-09-07 alongside Garage
# itself, no replacement — ADR-0002/ADR-0007/ADR-0039.)

# --- argocd namespace Phase 1 PSA labels (RFC #205, ADR-0017) -----------------

@test "argocd namespace.yaml exists" {
  [ -f "$REPO/gitops/argocd/namespace.yaml" ]
}

@test "argocd namespace.yaml has warn: restricted (Phase 1)" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd namespace.yaml has audit: restricted (Phase 1)" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-extras Application exists" {
  [ -f "$REPO/gitops/platform/argocd-extras.yaml" ]
}

@test "argocd-extras Application targets gitops/argocd" {
  run grep -q 'path: gitops/argocd' "$REPO/gitops/platform/argocd-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$REPO/gitops/platform/argocd-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd namespace.yaml enforces PSS restricted (Phase 2)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

# external-secrets namespace PSA restricted labels (RFC #229, ADR-0017) REMOVED
# 2026-09-07 (ADR-0042, supersedes ADR-0036): External Secrets Operator was
# dropped from the lab entirely, no replacement.
