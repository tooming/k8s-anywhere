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

@test "allow-vault-from-gateway allows ingress from kube-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: kube-system' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-vault-from-gateway allows ingress from Traefik pods" {
  run grep -q 'app.kubernetes.io/name: traefik' "$VAULT_NP/allow-vault-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "vault-networkpolicy ArgoCD Application targets the vault namespace" {
  run grep -q 'destNamespace: vault' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# 2026-08-06: found live that vault-unsealer (gitops/vault/unsealer.yaml, added
# 2026-07-29 specifically to fix a prior "Vault sealed for 4+ days undetected"
# incident) had no NetworkPolicy ingress rule of its own — under default-deny its
# `vault operator unseal` calls were silently dropped the whole time, so the SAME
# incident class recurred. Confirmed live: manual unseal from inside vault-0
# (no network) succeeds instantly; the identical call from vault-unsealer times out.
@test "allow-vault-from-unsealer.yaml exists in vault/networkpolicy/" {
  [ -f "$VAULT_NP/allow-vault-from-unsealer.yaml" ]
}

@test "allow-vault-from-unsealer allows port 8200 from the vault-unsealer pod (same namespace)" {
  run grep -q 'port: 8200' "$VAULT_NP/allow-vault-from-unsealer.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'app: vault-unsealer' "$VAULT_NP/allow-vault-from-unsealer.yaml"
  [ "$status" -eq 0 ]
}

@test "vault kustomization references allow-vault-from-unsealer.yaml" {
  run grep -q 'allow-vault-from-unsealer.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# Vault internal telemetry scrape (Alloy → Vault /v1/sys/metrics) REMOVED
# 2026-09-06 (ADR-0041, observability stack removed with no replacement).
@test "allow-vault-metrics-from-observability.yaml no longer exists (ADR-0041)" {
  [ ! -f "$VAULT_NP/allow-vault-metrics-from-observability.yaml" ]
}

@test "vault kustomization no longer references allow-vault-metrics-from-observability.yaml (ADR-0041)" {
  run grep -q 'allow-vault-metrics-from-observability.yaml' "$VAULT_NP/kustomization.yaml"
  [ "$status" -ne 0 ]
}
