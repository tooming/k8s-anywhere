#!/usr/bin/env bats
# Clusterless structural tests for the vault namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- vault namespace overlay (ADR-0016 §4 fan-out) ----------------------------
@test "vault networkpolicy kustomization.yaml exists" {
  [ -f "$VAULT_NP/kustomization.yaml" ]
}

@test "vault kustomization sets namespace: vault" {
  run grep -q 'namespace: vault' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "vault kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "vault kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso.yaml exists in vault/networkpolicy/" {
  [ -f "$VAULT_NP/allow-vault-from-eso.yaml" ]
}

@test "allow-vault-from-eso allows port 8200 (Vault API)" {
  run grep -q 'port: 8200' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso targets Vault server pods" {
  run grep -q 'app.kubernetes.io/name: vault' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'component: server' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso allows ingress from external-secrets namespace" {
  run grep -q 'kubernetes.io/metadata.name: external-secrets' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-eso allows ingress from ESO controller pods" {
  run grep -q 'app.kubernetes.io/name: external-secrets' "$VAULT_NP/allow-vault-from-eso.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway.yaml exists in vault/networkpolicy/" {
  [ -f "$VAULT_NP/allow-vault-from-gateway.yaml" ]
}

@test "allow-vault-from-gateway allows port 8200 (Vault API)" {
  run grep -q 'port: 8200' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application targets the vault namespace" {
  run grep -q 'destNamespace: vault' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
