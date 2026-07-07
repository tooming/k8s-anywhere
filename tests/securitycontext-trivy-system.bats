#!/usr/bin/env bats
# Clusterless structural tests for PSS *baseline* profile applied to the
# trivy-system namespace (ADR-0017 §Per-namespace profile, ADR-0022,
# ROADMAP auto/trivy-operator). baseline (not restricted) because scan-job pods
# unpack arbitrary OCI artifacts which exceeds the restricted profile; the
# controller itself is restricted-compatible but a single profile applies to
# all pods in the namespace.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/trivy-system/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/trivy-extras.yaml"
}

# --- namespace PSA baseline labels -------------------------------------------

@test "trivy-system namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "trivy-system namespace enforces PSS baseline" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "trivy-system namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "trivy-system namespace has warn: baseline" {
  run grep -q 'pod-security.kubernetes.io/warn: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "trivy-system namespace has audit: baseline" {
  run grep -q 'pod-security.kubernetes.io/audit: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "trivy-system namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -ne 0 ]
}

@test "trivy-system namespace does NOT enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- trivy-extras Application -------------------------------------------------

@test "trivy-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "trivy-extras Application targets gitops/trivy-system" {
  run grep -q 'path: gitops/trivy-system' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "trivy-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}
