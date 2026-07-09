#!/usr/bin/env bats
# Clusterless structural tests for the lab-gateway namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- lab-gateway namespace overlay (ADR-0016 §4 fan-out) ----------------------
@test "lab-gateway networkpolicy kustomization.yaml exists" {
  [ -f "$GATEWAY_NP/kustomization.yaml" ]
}

@test "lab-gateway kustomization sets namespace: lab-gateway" {
  run grep -q 'namespace: lab-gateway' "$GATEWAY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-gateway kustomization references the shared default-deny template" {
  run grep -q 'policies/default-deny.yaml' "$GATEWAY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-gateway kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'policies/allow-dns-and-apiserver.yaml' "$GATEWAY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-gateway kustomization has only three resources (baseline templates + ClusterIP bridge, no extra rules)" {
  run grep -c '^\s*-' "$GATEWAY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "lab-gateway-networkpolicy ArgoCD Application file exists" {
  [ -f "$REPO/gitops/platform/networkpolicy-appset.yaml" ]
}

@test "lab-gateway-networkpolicy ArgoCD Application targets the lab-gateway namespace" {
  run grep -q 'destNamespace: lab-gateway' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-gateway-networkpolicy ArgoCD Application is sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-gateway-networkpolicy ArgoCD Application sources from gitops/network/networkpolicy" {
  run grep -q 'gitops/network/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
