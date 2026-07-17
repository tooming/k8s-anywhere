#!/usr/bin/env bats
# Clusterless structural tests for the PSS *baseline* profile applied to the
# envoy-gateway-system namespace (ADR-0017 §Per-namespace profile, RFC #230).
# baseline (not restricted) because the gateway-helm chart's Envoy proxy data-plane
# pods run as UID 0 — restricted would have PSA reject every new proxy pod and break
# north-south traffic. See gitops/envoy-gateway-system/namespace.yaml for the flip
# condition.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith are what caused the recurring merge
# conflict between parallel PSS fan-out PRs (#238 vs #239). One scope = one file =
# no shared append anchor. Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/envoy-gateway-system/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/envoy-gateway-system-extras.yaml"
}

# --- namespace PSA baseline labels -------------------------------------------

@test "envoy-gateway-system namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "envoy-gateway-system namespace enforces PSS baseline" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system namespace has warn: baseline" {
  run grep -q 'pod-security.kubernetes.io/warn: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system namespace has audit: baseline" {
  run grep -q 'pod-security.kubernetes.io/audit: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 1 ]
}

@test "envoy-gateway-system-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "envoy-gateway-system-extras Application targets gitops/envoy-gateway-system" {
  run grep -q 'path: gitops/envoy-gateway-system' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}
