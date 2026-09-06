#!/usr/bin/env bats
# Clusterless structural tests for the external-secrets namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- external-secrets namespace overlay (ADR-0016 §4 fan-out) --------------------
@test "external-secrets networkpolicy kustomization.yaml exists" {
  [ -f "$ESO_NP/kustomization.yaml" ]
}

@test "external-secrets kustomization sets namespace: external-secrets" {
  run grep -q 'namespace: external-secrets' "$ESO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ESO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "external-secrets kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ESO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-metrics-ingress.yaml no longer exists (ADR-0041)" {
  [ ! -f "$ESO_NP/allow-eso-metrics-ingress.yaml" ]
}

@test "allow-eso-vault-egress.yaml exists in external-secrets/networkpolicy/" {
  [ -f "$ESO_NP/allow-eso-vault-egress.yaml" ]
}

@test "allow-eso-vault-egress allows port 8200 (Vault k8s auth endpoint)" {
  run grep -q 'port: 8200' "$ESO_NP/allow-eso-vault-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-vault-egress targets vault namespace" {
  run grep -q 'kubernetes.io/metadata.name: vault' "$ESO_NP/allow-eso-vault-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-vault-egress uses Egress policyType" {
  run grep -q 'Egress' "$ESO_NP/allow-eso-vault-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-appset.yaml contains external-secrets-networkpolicy entry" {
  run grep -q 'external-secrets-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-appset.yaml references gitops/external-secrets/networkpolicy path" {
  run grep -q 'gitops/external-secrets/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# The observability namespace's allow-alloy-egress-external.yaml (whose egress
# rule to external-secrets used to be asserted here) no longer exists (ADR-0041,
# observability stack removed with no replacement).

# --- allow-eso-webhook-from-apiserver: admission webhook ingress (found via a
# from-scratch `make up` — every namespace's ExternalSecret/ClusterSecretStore
# create/update times out through this webhook once default-deny lands without it) --

@test "allow-eso-webhook-from-apiserver.yaml exists in external-secrets/networkpolicy/" {
  [ -f "$ESO_NP/allow-eso-webhook-from-apiserver.yaml" ]
}

@test "external-secrets kustomization references allow-eso-webhook-from-apiserver.yaml" {
  run grep -q 'allow-eso-webhook-from-apiserver.yaml' "$ESO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# fromEntities remote-node, not ipBlock 10.43.0.1/32: k3s embeds the apiserver in
# the server node's own process, so its outbound webhook call carries Cilium's
# remote-node identity + the node's real pod-network IP as source — the apiserver
# Service ClusterIP is never the actual source address on an outbound connection,
# so an ipBlock rule against it silently never matches. Verified live with
# `cilium monitor --type drop` on a from-scratch cluster (the plain-NetworkPolicy
# ipBlock version tried first here reproduced the exact same timeout). The same
# fix was then applied to kyverno/cert-manager/keda/kargo's equivalent files,
# which shared the identical (previously untested) bug.
@test "allow-eso-webhook-from-apiserver is a CiliumNetworkPolicy using fromEntities remote-node" {
  run grep -q 'kind: CiliumNetworkPolicy' "$ESO_NP/allow-eso-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'remote-node' "$ESO_NP/allow-eso-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-webhook-from-apiserver does not regress to the broken ipBlock 10.43.0.1 pattern" {
  run grep -q -- '- ipBlock:' "$ESO_NP/allow-eso-webhook-from-apiserver.yaml"
  [ "$status" -ne 0 ]
}

@test "allow-eso-webhook-from-apiserver targets the webhook pod on port 10250" {
  run grep -q 'app.kubernetes.io/name: external-secrets-webhook' "$ESO_NP/allow-eso-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: "10250"' "$ESO_NP/allow-eso-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}
