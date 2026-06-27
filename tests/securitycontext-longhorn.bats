#!/usr/bin/env bats
# Clusterless structural tests for the PSS *privileged* profile applied to the
# longhorn-system namespace (ADR-0017 §Per-namespace profile, ADR-0013,
# ROADMAP auto/pss-np-longhorn). privileged (not restricted or baseline) because
# longhorn-manager and longhorn-csi-plugin require SYS_ADMIN, mount propagation,
# and host /dev; block storage cannot function under any other profile.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith caused recurring merge conflicts
# (#238 vs #239). One scope = one file = no shared append anchor.
# Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/longhorn/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/longhorn-extras.yaml"
}

# --- namespace PSA privileged labels -----------------------------------------

@test "longhorn-system namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "longhorn-system namespace enforces PSS privileged" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "longhorn-system namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "longhorn-system namespace has warn: privileged" {
  run grep -q 'pod-security.kubernetes.io/warn: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "longhorn-system namespace has audit: privileged" {
  run grep -q 'pod-security.kubernetes.io/audit: privileged' "$NS"
  [ "$status" -eq 0 ]
}

@test "longhorn-system namespace does NOT enforce restricted (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 1 ]
}

@test "longhorn-system namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 1 ]
}

# --- longhorn-extras Application ---------------------------------------------

@test "longhorn-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "longhorn-extras Application targets gitops/longhorn" {
  run grep -q 'path: gitops/longhorn' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "longhorn-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "longhorn-extras Application is auto-synced (namespace labels land before make longhorn-up)" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}
