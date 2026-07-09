#!/usr/bin/env bats
# Clusterless structural tests for the ack-system namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- ack-system namespace overlay (ADR-0016 §4 fan-out) --------------------------
@test "ack networkpolicy kustomization.yaml exists" {
  [ -f "$ACK_NP/kustomization.yaml" ]
}

@test "ack kustomization sets namespace: ack-system" {
  run grep -q 'namespace: ack-system' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "ack kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "ack kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ACK_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-ack-egress-moto.yaml exists in ack/networkpolicy/" {
  [ -f "$ACK_NP/allow-ack-egress-moto.yaml" ]
}

@test "allow-ack-egress-moto allows egress to port 5000 (moto HTTP API)" {
  run grep -q 'port: 5000' "$ACK_NP/allow-ack-egress-moto.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-ack-egress-moto allows egress to moto namespace" {
  run grep -q 'kubernetes.io/metadata.name: moto' "$ACK_NP/allow-ack-egress-moto.yaml"
  [ "$status" -eq 0 ]
}

@test "ack-networkpolicy ArgoCD Application targets the ack-system namespace" {
  run grep -q 'destNamespace: ack-system' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
