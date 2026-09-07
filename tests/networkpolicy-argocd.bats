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

@test "allow-argocd-server-from-gateway allows ingress from kube-system namespace" {
  run grep -q 'kube-system' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-server-from-gateway allows ingress from Traefik pods" {
  run grep -q 'app.kubernetes.io/name: traefik' "$ARGOCD_NP/allow-argocd-server-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argocd-from-alloy.yaml no longer exists (ADR-0041)" {
  [ ! -f "$ARGOCD_NP/allow-argocd-from-alloy.yaml" ]
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

@test "allow-argocd-repo-server-egress-forgejo.yaml no longer exists (Forgejo removed 2026-09-07, no replacement — ArgoCD clones GitHub directly now)" {
  [ ! -f "$ARGOCD_NP/allow-argocd-repo-server-egress-forgejo.yaml" ]
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

@test "allow-argocd-service-frontends.yaml no longer exists (dropped 2026-09-07, subsumed by intra-namespace)" {
  # Cilium's socket-LB pre-DNAT quirk (ADR-0014, removed 2026-09-07, no
  # replacement) was the only reason ArgoCD's own Service frontends needed a
  # separate ClusterIP-CIDR policy — kube-router enforces NetworkPolicy
  # post-DNAT, so allow-argocd-intra-namespace.yaml's podSelector:{} egress
  # rule already matches those same backend pods directly.
  [ ! -f "$ARGOCD_NP/allow-argocd-service-frontends.yaml" ]
}

@test "argocd networkpolicy kustomization wires the repo-server egress policy in its resources: list" {
  run grep -q 'allow-argocd-repo-server-egress-charts.yaml' "$ARGOCD_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
  # Scoped to the resources: list, not the whole file — the header comment
  # legitimately still names allow-argocd-service-frontends.yaml as history
  # (why it was dropped 2026-09-07), which a whole-file grep would false-positive on.
  run bash -c "awk '/^resources:/{f=1} f' '$ARGOCD_NP/kustomization.yaml' | grep -q 'allow-argocd-service-frontends.yaml'"
  [ "$status" -eq 1 ]
}

@test "argocd-networkpolicy ArgoCD Application targets the argocd namespace" {
  run grep -q 'destNamespace: argocd' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
