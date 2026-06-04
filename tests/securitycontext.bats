#!/usr/bin/env bats
# Clusterless structural tests for Pod Security Standards hardening (ADR-0017, RFC #83).
# Asserts the capstone pilot Deployment and Namespace manifest carry all required
# PSS restricted fields without spinning up a cluster.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOY="$REPO/gitops/apps/capstone/deployment.yaml"
  NS="$REPO/gitops/apps/capstone/namespace.yaml"
}

# --- namespace PSA labels ----------------------------------------------------

@test "capstone namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "capstone namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "capstone namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

# --- Deployment pod-level securityContext ------------------------------------

@test "capstone Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$DEPLOY"
  [ "$status" -eq 0 ]
}

# --- container-level securityContext -----------------------------------------

@test "capstone Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "capstone Deployment does not run as privileged" {
  run grep -q 'privileged: true' "$DEPLOY"
  [ "$status" -eq 1 ]
}
