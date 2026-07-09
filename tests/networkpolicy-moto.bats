#!/usr/bin/env bats
# Clusterless structural tests for the moto namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- moto namespace overlay (ADR-0016 §4 fan-out) --------------------------------
@test "moto networkpolicy kustomization.yaml exists" {
  [ -f "$MOTO_NP/kustomization.yaml" ]
}

@test "moto kustomization sets namespace: moto" {
  run grep -q 'namespace: moto' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "moto kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "moto kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$MOTO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack.yaml exists in moto/networkpolicy/" {
  [ -f "$MOTO_NP/allow-moto-from-ack.yaml" ]
}

@test "allow-moto-from-ack allows port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack targets pods with app: moto" {
  run grep -q 'app: moto' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-ack allows ingress from ack-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: ack-system' "$MOTO_NP/allow-moto-from-ack.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway.yaml exists in moto/networkpolicy/" {
  [ -f "$MOTO_NP/allow-moto-from-gateway.yaml" ]
}

@test "allow-moto-from-gateway allows port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-moto-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$MOTO_NP/allow-moto-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "moto-networkpolicy ArgoCD Application targets the moto namespace" {
  run grep -q 'destNamespace: moto' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
