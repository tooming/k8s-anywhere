#!/usr/bin/env bats
# Clusterless structural tests for the capstone namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- capstone namespace overlay (ADR-0016 §4 fan-out) ------------------------
@test "capstone networkpolicy kustomization.yaml exists" {
  [ -f "$CAPSTONE_NP/kustomization.yaml" ]
}

@test "capstone kustomization sets namespace: capstone" {
  run grep -q 'namespace: capstone' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$CAPSTONE_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway.yaml exists in capstone/networkpolicy/" {
  [ -f "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml" ]
}

@test "allow-capstone-ingress-from-gateway allows port 8080 (capstone HTTP)" {
  run grep -q 'port: 8080' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway targets pods with app: capstone" {
  run grep -q 'app: capstone' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway allows ingress from kube-system namespace" {
  run grep -q 'kube-system' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-ingress-from-gateway allows ingress from Traefik pods" {
  run grep -q 'app.kubernetes.io/name: traefik' "$CAPSTONE_NP/allow-capstone-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-egress-tempo.yaml no longer exists (ADR-0041)" {
  [ ! -f "$CAPSTONE_NP/allow-capstone-egress-tempo.yaml" ]
}

@test "capstone-networkpolicy ArgoCD Application targets the capstone namespace" {
  run grep -q 'destNamespace: capstone' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
