#!/usr/bin/env bats
# Clusterless structural tests for PSS *privileged* profile applied to the
# node-exporter namespace (ADR-0017 §Per-namespace profile, ROADMAP
# auto/argo-rollouts-controller wave extras). privileged (not restricted or
# baseline) because the node-exporter DaemonSet mounts host paths /proc and
# /sys (required for host-level metrics collection) which are forbidden under
# the baseline and restricted profiles.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/node-exporter/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/node-exporter-extras.yaml"
}

# --- namespace PSA privileged labels -----------------------------------------

@test "node-exporter namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "node-exporter namespace enforces PSS privileged" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "node-exporter namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "node-exporter namespace has warn: privileged" {
  run grep -q 'pod-security.kubernetes.io/warn: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "node-exporter namespace has audit: privileged" {
  run grep -q 'pod-security.kubernetes.io/audit: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "node-exporter namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -ne 0 ]
}

@test "node-exporter namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

# --- node-exporter-extras Application ----------------------------------------

@test "node-exporter-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "node-exporter-extras Application targets gitops/node-exporter" {
  run grep -q 'path: gitops/node-exporter' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "node-exporter-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "node-exporter-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}
