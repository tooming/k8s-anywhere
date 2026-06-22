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

@test "allow-eso-metrics-ingress.yaml exists in external-secrets/networkpolicy/" {
  [ -f "$ESO_NP/allow-eso-metrics-ingress.yaml" ]
}

@test "allow-eso-metrics-ingress allows port 8080 (ESO controller-runtime metrics)" {
  run grep -q 'port: 8080' "$ESO_NP/allow-eso-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-metrics-ingress allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ESO_NP/allow-eso-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-eso-metrics-ingress targets ESO controller pods by name label" {
  run grep -q 'app.kubernetes.io/name: external-secrets' "$ESO_NP/allow-eso-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
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

@test "allow-alloy-egress-external.yaml includes external-secrets egress on port 8080" {
  run grep -q 'kubernetes.io/metadata.name: external-secrets' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}
