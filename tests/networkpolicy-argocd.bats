#!/usr/bin/env bats
# Clusterless structural tests for the argocd namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- argocd namespace overlay (ADR-0016 §4 fan-out) ---------------------------
@test "argocd networkpolicy kustomization.yaml exists" {
  [ -f "$ARGOCD_NP/kustomization.yaml" ]
}

@test "argocd kustomization sets namespace: argocd" {
  run grep -q 'namespace: argocd' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml" ]
}

@test "allow-argocd-server-from-gateway allows port 8080 (ArgoCD server HTTP)" {
  run grep -q 'port: 8080' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway targets argocd-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-server' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'envoy-gateway-system' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from Envoy proxy pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-from-alloy.yaml" ]
}

@test "allow-argocd-from-alloy allows metrics port 8082 (application-controller)" {
  run grep -q 'port: 8082' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows metrics port 8083 (argocd-server-metrics)" {
  run grep -q 'port: 8083' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows metrics port 8084 (repo-server-metrics)" {
  run grep -q 'port: 8084' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy allows ingress from Alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$ARGOCD_NP/allow-argocd-from-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-intra-namespace.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-intra-namespace.yaml" ]
}

@test "allow-argocd-intra-namespace allows both Ingress and Egress policyTypes" {
  run grep -c 'Ingress\|Egress' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-argocd-intra-namespace uses an empty podSelector (matches all pods)" {
  run grep -q 'podSelector: {}' "$ARGOCD_NP/allow-argocd-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-forgejo.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml" ]
}

@test "allow-argocd-repo-server-egress-forgejo allows port 2223 (Forgejo SSH)" {
  run grep -q 'port: 2223' "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-forgejo targets argocd-repo-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-repo-server' "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-forgejo uses an ipBlock for the host CIDR" {
  run grep -q 'ipBlock:' "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-charts.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml" ]
}

@test "allow-argocd-repo-server-egress-charts allows TCP 443 (Helm/OCI chart pull)" {
  run grep -qE 'port: "?443"?' "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-repo-server-egress-charts targets argocd-repo-server pods" {
  run grep -q 'app.kubernetes.io/name: argocd-repo-server' "$ARGOCD_NP/allow-argocd-repo-server-egress-charts.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-service-frontends.yaml exists in argocd/networkpolicy/" {
  [ -f "$ARGOCD_NP/allow-argocd-service-frontends.yaml" ]
}

@test "allow-argocd-service-frontends is a CiliumNetworkPolicy (kube-proxy-free frontend match)" {
  run grep -q 'kind: CiliumNetworkPolicy' "$ARGOCD_NP/allow-argocd-service-frontends.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-service-frontends permits the Redis and repo-server service ports" {
  run grep -q 'port: "6379"' "$ARGOCD_NP/allow-argocd-service-frontends.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: "8081"' "$ARGOCD_NP/allow-argocd-service-frontends.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd networkpolicy kustomization wires both repo-server egress policies + service frontends" {
  run grep -q 'allow-argocd-repo-server-egress-charts.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'allow-argocd-service-frontends.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-networkpolicy ArgoCD Application targets the argocd namespace" {
  run grep -q 'destNamespace: argocd' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
