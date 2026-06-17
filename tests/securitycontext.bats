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

# --- baseline carve-out namespaces (ADR-0017 §Per-namespace profile) ----------

@test "vault namespace.yaml enforces PSS baseline" {
  NS="$REPO/gitops/vault/namespace.yaml"
  [ -f "$NS" ]
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "storage namespace.yaml enforces PSS baseline" {
  NS="$REPO/gitops/storage/garage/namespace.yaml"
  [ -f "$NS" ]
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "tidb namespace.yaml enforces PSS baseline" {
  NS="$REPO/gitops/tidb/namespace.yaml"
  [ -f "$NS" ]
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "tidb-admin namespace.yaml enforces PSS baseline" {
  NS="$REPO/gitops/tidb-admin/namespace.yaml"
  [ -f "$NS" ]
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace.yaml exists and enforces PSS baseline" {
  NS="$REPO/gitops/kyverno/namespace.yaml"
  [ -f "$NS" ]
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$NS"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace.yaml has enforce-version: latest" {
  NS="$REPO/gitops/kyverno/namespace.yaml"
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

# --- argocd namespace Phase 1 PSA labels (RFC #205, ADR-0017) -----------------

@test "argocd namespace.yaml exists" {
  [ -f "$REPO/gitops/argocd/namespace.yaml" ]
}

@test "argocd namespace.yaml has warn: restricted (Phase 1)" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd namespace.yaml has audit: restricted (Phase 1)" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-extras Application exists" {
  [ -f "$REPO/gitops/platform/argocd-extras.yaml" ]
}

@test "argocd-extras Application targets gitops/argocd" {
  run grep -q 'path: gitops/argocd' "$REPO/gitops/platform/argocd-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$REPO/gitops/platform/argocd-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd namespace.yaml does NOT have enforce label (Phase 1 only)" {
  run grep -q 'pod-security.kubernetes.io/enforce' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 1 ]
}
