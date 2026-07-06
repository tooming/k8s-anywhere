#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# harbor namespace (ADR-0017 §Per-namespace profile, ADR-0024,
# ROADMAP auto/harbor-application). restricted because Harbor core/registry/
# jobservice run as non-root UID 10000 and the bundled Postgres uses Bitnami
# non-root UID 1001; the profile is verified on the chart's actual pod specs.
# Harbor is on-demand (`make harbor-up`) but the namespace PSA floor is
# always-on via harbor-extras, so the labels are present whether or not Harbor
# is currently running.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/harbor/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/harbor-extras.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "harbor namespace.yaml exists (PSS labels)" {
  [ -f "$NS" ]
}

@test "harbor namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "harbor namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "harbor namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "harbor namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "harbor namespace does NOT enforce baseline (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -ne 0 ]
}

@test "harbor namespace does NOT enforce privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$NS"
  [ "$status" -ne 0 ]
}

# --- harbor-extras Application ------------------------------------------------

@test "harbor-extras Application exists (PSA floor)" {
  [ -f "$EXTRAS" ]
}

@test "harbor-extras Application targets gitops/harbor" {
  run grep -q 'path: gitops/harbor' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application is auto-synced" {
  run grep -q 'automated:' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}
