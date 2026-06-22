#!/usr/bin/env bats
# Clusterless structural tests for the tidb-admin namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- tidb-admin namespace overlay (ADR-0016 §4 fan-out) --------------------------
@test "tidb-admin networkpolicy kustomization.yaml exists" {
  [ -f "$TIDB_ADMIN_NP/kustomization.yaml" ]
}

@test "tidb-admin kustomization sets namespace: tidb-admin" {
  run grep -q 'namespace: tidb-admin' "$TIDB_ADMIN_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-admin kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$TIDB_ADMIN_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-admin kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$TIDB_ADMIN_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-admin-egress-tidb.yaml exists in tidb-admin/networkpolicy/" {
  [ -f "$TIDB_ADMIN_NP/allow-tidb-admin-egress-tidb.yaml" ]
}

@test "allow-tidb-admin-egress-tidb allows egress to tidb namespace" {
  run grep -q 'kubernetes.io/metadata.name: tidb' "$TIDB_ADMIN_NP/allow-tidb-admin-egress-tidb.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tidb-admin-egress-tidb uses Egress policyType" {
  run grep -q 'Egress' "$TIDB_ADMIN_NP/allow-tidb-admin-egress-tidb.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-admin-networkpolicy ArgoCD Application targets the tidb-admin namespace" {
  run grep -q 'destNamespace: tidb-admin' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "tidb-admin-networkpolicy ArgoCD Application sources from gitops/tidb-admin/networkpolicy" {
  run grep -q 'gitops/tidb-admin/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
