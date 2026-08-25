#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the keda
# namespace (ADR-0017 §Per-namespace profile, ADR-0029). The chart's operator/
# metricServer/webhooks all default to the full restricted securityContext
# (verified against the pinned chart's values.yaml, see ADR-0029 §"PSA profile")
# — no valuesObject override needed, second component after cert-manager to
# land at restricted with zero carve-out. These tests confirm the namespace
# labels are in place and the keda-extras Application is wired correctly.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/keda/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/keda-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "keda namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "keda namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "keda namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "keda namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "keda namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "keda namespace does NOT enforce baseline or privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- keda-extras Application -------------------------------------------

@test "keda-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "keda-extras Application targets gitops/keda" {
  run grep -q 'path: gitops/keda' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "keda-extras Application runs at sync-wave 6 (moved alongside keda, ADR-0029 webhook-TLS follow-up)" {
  run grep -q 'sync-wave: "6"' "$EXTRAS"
  [ "$status" -eq 0 ]
}

# Converted always-on -> on-demand 2026-08-25 (ADR-0029's Re-evaluation log).
@test "keda-extras Application is manual sync only (on-demand)" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 1 ]
}
