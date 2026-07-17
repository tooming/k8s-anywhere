#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# kargo namespace (ADR-0017 §Per-namespace profile, ROADMAP auto/adr-0017-kargo-row).
# The kargo chart has NO pod-level securityContext knob of its own (verified
# live — see gitops/platform/kargo.yaml's comment and
# gitops/kyverno/policies/add-default-runasnonroot.yaml); gitops/platform/kargo.yaml
# sets global.securityContext (UID 1000, non-root) at the container level, and
# the add-default-runasnonroot mutate policy backfills the pod-level
# runAsNonRoot the chart can't set itself. These tests confirm the namespace
# labels are in place and the kargo-extras Application is auto-synced (PSA
# floor before make kargo-up).
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/kargo/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/kargo-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "kargo namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "kargo namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "kargo namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "kargo namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "kargo namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "kargo namespace does not enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

@test "kargo namespace does not enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- kargo-extras Application -------------------------------------------------

@test "kargo-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "kargo-extras Application targets gitops/kargo" {
  run grep -q 'path: gitops/kargo' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "kargo-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "kargo-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}
