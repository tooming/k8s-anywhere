#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# cert-manager namespace (ADR-0017 §Per-namespace profile, ADR-0028).
# The chart's controller/webhook/cainjector all default to the full restricted
# securityContext (verified against the pinned chart's values.yaml, see
# ADR-0028 §"PSA profile") — no valuesObject override needed, unlike most
# first-cut components in this lab. These tests confirm the namespace labels
# are in place and the cert-manager-extras Application is wired correctly.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/cert-manager/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/cert-manager-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "cert-manager namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "cert-manager namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "cert-manager namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "cert-manager namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "cert-manager namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "cert-manager namespace does NOT enforce baseline or privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- cert-manager-extras Application -------------------------------------------

@test "cert-manager-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "cert-manager-extras Application targets gitops/cert-manager" {
  run grep -q 'path: gitops/cert-manager' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "cert-manager-extras Application runs at sync-wave 0" {
  run grep -q 'sync-wave: "0"' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "cert-manager-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}
