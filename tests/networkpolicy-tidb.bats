#!/usr/bin/env bats
# Clusterless structural tests for the tidb namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- tidb namespace overlay (ADR-0016 §4 fan-out) --------------------------------
@test "tidb networkpolicy kustomization.yaml exists" {
  [ -f "$TIDB_NP/kustomization.yaml" ]
}

@test "tidb kustomization sets namespace: tidb" {
  run grep -q 'namespace: tidb' "$TIDB_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$TIDB_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$TIDB_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-intra-namespace.yaml exists in tidb/networkpolicy/" {
  [ -f "$TIDB_NP/allow-tidb-intra-namespace.yaml" ]
}

@test "allow-tidb-intra-namespace allows both Ingress and Egress policyTypes" {
  run grep -c 'Ingress\|Egress' "$TIDB_NP/allow-tidb-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-tidb-intra-namespace uses an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$TIDB_NP/allow-tidb-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-from-tidb-admin.yaml exists in tidb/networkpolicy/" {
  [ -f "$TIDB_NP/allow-tidb-from-tidb-admin.yaml" ]
}

@test "allow-tidb-from-tidb-admin allows ingress from tidb-admin namespace" {
  run grep -q 'kubernetes.io/metadata.name: tidb-admin' "$TIDB_NP/allow-tidb-from-tidb-admin.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-from-tidb-admin allows egress to tidb-admin namespace" {
  run grep -q 'tidb-admin' "$TIDB_NP/allow-tidb-from-tidb-admin.yaml"
  [ "$status" -eq 0 ]
  run grep -c 'tidb-admin' "$TIDB_NP/allow-tidb-from-tidb-admin.yaml"
  [ "$output" -ge 2 ]
}

@test "allow-tidb-kubelet-egress.yaml exists in tidb/networkpolicy/" {
  [ -f "$TIDB_NP/allow-tidb-kubelet-egress.yaml" ]
}

@test "allow-tidb-kubelet-egress allows port 10250 (TiKV topology probe to kubelet)" {
  run grep -q 'port: 10250' "$TIDB_NP/allow-tidb-kubelet-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-kubelet-egress uses an ipBlock for node CIDR" {
  run grep -q 'ipBlock:' "$TIDB_NP/allow-tidb-kubelet-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-from-observability.yaml exists in tidb/networkpolicy/" {
  [ -f "$TIDB_NP/allow-tidb-from-observability.yaml" ]
}

@test "allow-tidb-from-observability allows port 10080 (TiDB status / Alloy scrape)" {
  run grep -q 'port: 10080' "$TIDB_NP/allow-tidb-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-from-observability allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$TIDB_NP/allow-tidb-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-networkpolicy ArgoCD Application targets the tidb namespace" {
  run grep -q 'destNamespace: tidb' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-networkpolicy ArgoCD Application sources from gitops/tidb/networkpolicy" {
  run grep -q 'gitops/tidb/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
