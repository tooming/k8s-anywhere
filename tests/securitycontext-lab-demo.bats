#!/usr/bin/env bats
# Clusterless structural tests for the PSS *baseline* profile applied to the
# lab-demo namespace (ADR-0017 §Per-namespace profile, ROADMAP auto/pss-np-lab-demo).
# baseline (not restricted) because jaegertracing/example-hotrod runs as root —
# restricted would have PSA reject the pod. baseline blocks privileged containers
# and host-namespace use while permitting the root UID.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith are what caused the recurring merge
# conflict between parallel PSS fan-out PRs (#238 vs #239). One scope = one file =
# no shared append anchor. Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/apps/demo/namespace.yaml"
}

# --- namespace PSA baseline labels -------------------------------------------

@test "lab-demo namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "lab-demo namespace enforces PSS baseline" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has warn: baseline" {
  run grep -q 'pod-security.kubernetes.io/warn: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has audit: baseline" {
  run grep -q 'pod-security.kubernetes.io/audit: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 1 ]
}
