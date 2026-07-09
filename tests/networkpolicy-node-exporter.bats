#!/usr/bin/env bats
# Clusterless structural tests for the node-exporter namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- node-exporter namespace overlay (ADR-0016 §4 fan-out) -----------------------
@test "node-exporter networkpolicy kustomization.yaml exists" {
  [ -f "$NODE_EXPORTER_NP/kustomization.yaml" ]
}

@test "node-exporter kustomization sets namespace: node-exporter" {
  run grep -q 'namespace: node-exporter' "$NODE_EXPORTER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "node-exporter kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$NODE_EXPORTER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "node-exporter kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$NODE_EXPORTER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}


# --- metrics allow (Alloy → node-exporter TCP 9100) -------------------------------
@test "allow-node-exporter-metrics-ingress.yaml exists in node-exporter/networkpolicy/" {
  [ -f "$NODE_EXPORTER_NP/allow-node-exporter-metrics-ingress.yaml" ]
}

@test "node-exporter kustomization references the metrics allow file" {
  run grep -q 'allow-node-exporter-metrics-ingress.yaml' "$NODE_EXPORTER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-node-exporter-metrics-ingress allows ingress on port 9100" {
  run grep -q 'port: 9100' "$NODE_EXPORTER_NP/allow-node-exporter-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-node-exporter-metrics-ingress restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$NODE_EXPORTER_NP/allow-node-exporter-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-node-exporter-metrics-ingress uses Ingress policyType" {
  run grep -q 'Ingress' "$NODE_EXPORTER_NP/allow-node-exporter-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-node-exporter-metrics-ingress selects node-exporter pods by label" {
  run grep -q 'app.kubernetes.io/name: prometheus-node-exporter' "$NODE_EXPORTER_NP/allow-node-exporter-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

# --- node-exporter-networkpolicy appset entry (networkpolicy-appset.yaml wave 4) --
@test "node-exporter-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'node-exporter-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "node-exporter-networkpolicy appset entry references gitops/node-exporter/networkpolicy" {
  run grep -q 'gitops/node-exporter/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
