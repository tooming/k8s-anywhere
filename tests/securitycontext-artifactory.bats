#!/usr/bin/env bats
# Clusterless structural tests for the PSS *baseline* profile applied to the
# artifactory namespace (ADR-0017 §Per-namespace profile, RFC #287,
# ROADMAP auto/pss-np-artifactory). baseline (not restricted) because JVM
# initContainers in jfrog/artifactory-oss run as root UID 0 for chown operations;
# restricted is not viable without upstream chart changes.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith caused recurring merge conflicts
# (#238 vs #239). One scope = one file = no shared append anchor.
# Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/artifactory/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/artifactory-extras.yaml"
}

# --- namespace PSA baseline labels -------------------------------------------

@test "artifactory namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "artifactory namespace enforces PSS baseline" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "artifactory namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "artifactory namespace has warn: baseline" {
  run grep -q 'pod-security.kubernetes.io/warn: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "artifactory namespace has audit: baseline" {
  run grep -q 'pod-security.kubernetes.io/audit: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "artifactory namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 1 ]
}

@test "artifactory namespace does NOT enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -eq 1 ]
}

# --- artifactory-extras Application ------------------------------------------

@test "artifactory-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "artifactory-extras Application targets gitops/artifactory" {
  run grep -q 'path: gitops/artifactory' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "artifactory-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "artifactory-extras Application is auto-synced (namespace labels land before make artifactory-up)" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "artifactory-extras Application has sync-wave 0 annotation" {
  run grep -q 'sync-wave: "0"' "$EXTRAS"
  [ "$status" -eq 0 ]
}
