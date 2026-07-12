#!/usr/bin/env bats
# Clusterless structural tests for Pod Security Standards hardening (ADR-0017, RFC #83).
# Asserts the capstone pilot Deployment and Namespace manifest carry all required
# PSS restricted fields without spinning up a cluster.
#
# FROZEN — do NOT add new @test blocks here. Two parallel PSS fan-out PRs appending a
# per-namespace block to this file's EOF is what caused the recurring merge conflict
# (#238 vs #239). New per-namespace / per-scope security-context tests go in their own
# tests/securitycontext-<scope>.bats file (see -data, -observability, -envoy-gateway-system).
# This freeze is enforced mechanically by scripts/securitycontext-tests-check.sh (make ci);
# if you intentionally rename/edit an existing test here, run `make securitycontext-tests-mark`.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOY="$REPO/gitops/apps/capstone/deployment.yaml"
  NS="$REPO/gitops/apps/capstone/namespace.yaml"
  ESO="$REPO/gitops/platform/external-secrets.yaml"
  load lib/yq
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

@test "argocd namespace.yaml enforces PSS restricted (Phase 2)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/argocd/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- external-secrets namespace PSA restricted labels (RFC #229, ADR-0017) ----

@test "external-secrets namespace.yaml exists" {
  [ -f "$REPO/gitops/external-secrets/namespace.yaml" ]
}

@test "external-secrets namespace.yaml enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/external-secrets/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets namespace.yaml has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/external-secrets/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets namespace.yaml has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$REPO/gitops/external-secrets/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets namespace.yaml has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/external-secrets/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets-extras Application exists" {
  [ -f "$REPO/gitops/platform/external-secrets-extras.yaml" ]
}

@test "external-secrets-extras Application targets gitops/external-secrets" {
  run grep -q 'path: gitops/external-secrets' "$REPO/gitops/platform/external-secrets-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets-extras Application uses ServerSideApply" {
  run grep -q 'ServerSideApply=true' "$REPO/gitops/platform/external-secrets-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets chart valuesObject sets runAsNonRoot: true" {
  # The chart has no global.podSecurityContext key — main/webhook/certController
  # each need their OWN pod-level podSecurityContext.runAsNonRoot, or
  # require-pod-security-restricted (ADR-0017) rejects the pod at admission
  # (regression: #340, a rollout restart during vault-bootstrap got blocked
  # because the values were nested under the wrong, silently-ignored key).
  for path in '.podSecurityContext.runAsNonRoot' '.webhook.podSecurityContext.runAsNonRoot' '.certController.podSecurityContext.runAsNonRoot'; do
    [ "$(yqs ".spec.source.helm.valuesObject${path}" "$ESO")" = "true" ]
  done
}

@test "external-secrets chart valuesObject sets readOnlyRootFilesystem: true" {
  for path in '.securityContext.readOnlyRootFilesystem' '.webhook.securityContext.readOnlyRootFilesystem' '.certController.securityContext.readOnlyRootFilesystem'; do
    [ "$(yqs ".spec.source.helm.valuesObject${path}" "$ESO")" = "true" ]
  done
}

@test "external-secrets chart valuesObject drops ALL capabilities" {
  for path in '.securityContext.capabilities.drop[0]' '.webhook.securityContext.capabilities.drop[0]' '.certController.securityContext.capabilities.drop[0]'; do
    [ "$(yqs ".spec.source.helm.valuesObject${path}" "$ESO")" = "ALL" ]
  done
}
