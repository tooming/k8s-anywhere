#!/usr/bin/env bats
# Clusterless structural tests for PSS *restricted* profile applied to the
# kro namespace (ADR-0017 §Per-namespace profile, ROADMAP auto/pss-kro-namespace).
# The KRO controller chart already ships with a hardened securityContext in
# gitops/platform/kro.yaml valuesObject (UID 65534, readOnlyRootFilesystem: true,
# capabilities.drop: [ALL]) — these tests confirm the namespace labels are in place
# and the kro-extras Application is wired correctly.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith cause recurring merge conflicts.
# One scope = one file = no shared append anchor. Enforced by
# scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/kro/namespace.yaml"
  EXTRAS="$REPO/gitops/platform/kro-extras.yaml"
  APP="$REPO/gitops/platform/kro.yaml"
}

# --- deployment securityContext (the chart's real key, not containerSecurityContext) ---
# The kro Helm chart's container-level security fields live under
# `deployment.securityContext` — NOT `deployment.containerSecurityContext` (a
# non-existent, silently-dropped key; same dead-key bug class as PR #493's
# Pyroscope fix). Found while diffing the chart's values.yaml for the
# 0.4.1 -> 0.9.2 bump; the key was wrong at 0.4.1 too, so this securityContext
# override never actually applied.

@test "kro Application sets deployment.securityContext (not the dead containerSecurityContext key)" {
  run grep -q '^          securityContext:' "$APP"
  [ "$status" -eq 0 ]
}

@test "kro Application does not use the dead containerSecurityContext key" {
  run grep -q 'containerSecurityContext' "$APP"
  [ "$status" -eq 1 ]
}

@test "kro Application securityContext sets allowPrivilegeEscalation: false" {
  run grep -A5 '^          securityContext:' "$APP"
  [ "$status" -eq 0 ]
  [[ "$output" == *"allowPrivilegeEscalation: false"* ]]
}

@test "kro Application securityContext sets readOnlyRootFilesystem: true" {
  run grep -A5 '^          securityContext:' "$APP"
  [ "$status" -eq 0 ]
  [[ "$output" == *"readOnlyRootFilesystem: true"* ]]
}

@test "kro Application securityContext drops ALL capabilities" {
  run grep -A6 '^          securityContext:' "$APP"
  [ "$status" -eq 0 ]
  [[ "$output" == *"drop:"* ]]
  [[ "$output" == *"- ALL"* ]]
}

# --- chart pin ----------------------------------------------------------------

@test "kro Application chart pin is 0.9.x (not the old 0.4.1)" {
  run grep -q 'targetRevision: 0\.9\.' "$APP"
  [ "$status" -eq 0 ]
}

# --- namespace PSA restricted labels -----------------------------------------

@test "kro namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "kro namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "kro namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "kro namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "kro namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

# --- kro-extras Application --------------------------------------------------

@test "kro-extras Application exists" {
  [ -f "$EXTRAS" ]
}

@test "kro-extras Application targets gitops/kro" {
  run grep -q 'path: gitops/kro' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "kro-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$EXTRAS"
  [ "$status" -eq 0 ]
}

@test "kro-extras Application does not create namespace (SSA labels only)" {
  run grep -q 'CreateNamespace=false' "$EXTRAS"
  [ "$status" -eq 0 ]
}
