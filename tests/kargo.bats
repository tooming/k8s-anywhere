#!/usr/bin/env bats
# Clusterless structural tests for Kargo (promotion-orchestration engine, ADR-0023).
# Validates GitOps wiring (Application shape, chart pin, ON-DEMAND guard for the Helm
# release, ALWAYS-ON for kargo-extras namespace pre-creation), namespace PSA labels,
# HTTPRoute, NetworkPolicy overlay, Kargo Project/Warehouse/Stage shape, and admin
# ExternalSecret — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (ON-DEMAND, no auto-sync) ----------------------
@test "kargo Application exists" {
  [ -f "$REPO/gitops/platform/kargo.yaml" ]
}

@test "kargo Application sources the chart from charts.kargo.io" {
  run grep -q 'repoURL: https://charts.kargo.io' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application pins a specific chart version" {
  run grep -qE 'targetRevision: [0-9]+\.[0-9]+\.[0-9]+' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 1 ]
}

@test "kargo Application targets the kargo namespace" {
  run grep -q 'namespace: kargo' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application disables TLS self-signed cert (plain HTTP inside cluster)" {
  run grep -q 'generate: false' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application sets controller memory limit" {
  run grep -q 'memory: 128Mi' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application sets api memory limit to 256Mi" {
  run grep -q 'memory: 256Mi' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application enables admin account" {
  run grep -q 'enabled: true' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application references the kargo-admin-credentials Secret" {
  run grep -q 'kargo-admin-credentials' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-extras Application (namespace + route pre-creation, wave 0) -------
@test "kargo-extras Application exists" {
  [ -f "$REPO/gitops/platform/kargo-extras.yaml" ]
}

@test "kargo-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-extras sources the gitops/kargo git path" {
  run grep -q 'path: gitops/kargo' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-extras is ALWAYS-ON (has automated sync block; PSA floor before make kargo-up)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-networkpolicy Application (wave 4) --------------------------------
@test "kargo-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/kargo-networkpolicy.yaml" ]
}

@test "kargo-networkpolicy runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-networkpolicy is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 1 ]
}

# --- kargo-project Application (wave 6) -------------------------------------
@test "kargo-project Application exists" {
  [ -f "$REPO/gitops/platform/kargo-project.yaml" ]
}

@test "kargo-project runs at sync-wave 6 (after kargo installs CRDs)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$REPO/gitops/platform/kargo-project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-project.yaml"
  [ "$status" -eq 1 ]
}

# --- Namespace PSA labels ----------------------------------------------------
@test "kargo namespace.yaml exists" {
  [ -f "$REPO/gitops/kargo/namespace.yaml" ]
}

@test "kargo namespace enforces PSA restricted (ADR-0017)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/kargo/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- HTTPRoute ---------------------------------------------------------------
@test "kargo HTTPRoute exists" {
  [ -f "$REPO/gitops/kargo/route.yaml" ]
}

@test "kargo HTTPRoute exposes kargo.127.0.0.1.nip.io" {
  run grep -q 'kargo.127.0.0.1.nip.io' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo HTTPRoute targets the kargo-api Service on port 80" {
  run grep -q 'name: kargo-api' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: 80' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay ---------------------------------------------------
@test "kargo NetworkPolicy kustomization.yaml exists" {
  [ -f "$REPO/gitops/kargo/networkpolicy/kustomization.yaml" ]
}

@test "kargo NetworkPolicy kustomization references the shared default-deny template" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/kargo/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy kustomization references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/kargo/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy allows Envoy Gateway ingress to API server" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-api-from-gateway.yaml" ]
}

@test "kargo NetworkPolicy allows kube-apiserver webhook callbacks" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml" ]
}

@test "kargo webhook policy allows TCP 9443 from kube-apiserver IP" {
  run grep -q 'port: 9443' "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q '10.43.0.1/32' "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy allows egress to ArgoCD" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-egress-argocd.yaml" ]
}

@test "kargo NetworkPolicy allows egress to image registry" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-egress-registry.yaml" ]
}

# --- Kargo Project / Warehouse / Stage resources ----------------------------
@test "kargo-project manifest exists" {
  [ -f "$REPO/gitops/kargo-project/project.yaml" ]
}

@test "kargo-project declares a Kargo Project named capstone-pipeline" {
  run grep -q 'kind: Project' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'name: capstone-pipeline' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project declares a Warehouse for the capstone image" {
  run grep -q 'kind: Warehouse' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'artifactory.127.0.0.1.nip.io/docker-local/hello' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "Warehouse uses Digest tag-selection strategy" {
  run grep -q 'tagSelectionStrategy: Digest' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project declares dev and prod Stages" {
  run grep -q 'name: dev' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'name: prod' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "dev Stage subscribes directly to the Warehouse (auto-promote)" {
  run grep -q 'direct: true' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "prod Stage subscribes to Freight from dev Stage (manual gate)" {
  run grep -c 'stages:' "$REPO/gitops/kargo-project/project.yaml"
  [ "$output" -ge 1 ]
  run grep -q '\- dev' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "Stage promotion template uses argocd-update step" {
  run grep -q 'uses: argocd-update' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-update step targets the capstone Application in argocd namespace" {
  run grep -q 'name: capstone' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'namespace: argocd' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

# --- Admin credentials ExternalSecret ----------------------------------------
@test "kargo admin ExternalSecret exists" {
  [ -f "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml" ]
}

@test "kargo admin ExternalSecret targets kargo-admin-credentials Secret" {
  run grep -q 'kargo-admin-credentials' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo admin ExternalSecret references Vault path kargo/admin" {
  run grep -q 'key: kargo/admin' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo admin ExternalSecret is in the kargo namespace" {
  run grep -q 'namespace: kargo' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Capstone kustomization.yaml (enables Kargo image override) --------------
@test "capstone kustomization.yaml exists (enables kustomize mode for Kargo)" {
  [ -f "$REPO/gitops/apps/capstone/kustomization.yaml" ]
}

@test "capstone kustomization.yaml includes deployment.yaml" {
  run grep -q 'deployment.yaml' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization.yaml includes rollout.yaml" {
  run grep -q 'rollout.yaml' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization.yaml excludes networkpolicy directory (managed separately)" {
  run grep -q '^\s*- networkpolicy' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 1 ]
}
