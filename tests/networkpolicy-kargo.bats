#!/usr/bin/env bats
# Clusterless structural tests for the kargo namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, ADR-0023). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- kargo namespace overlay (ADR-0016 §4 fan-out, ADR-0023) ---------------------
@test "kargo networkpolicy kustomization.yaml exists" {
  [ -f "$KARGO_NP/kustomization.yaml" ]
}

@test "kargo kustomization sets namespace: kargo" {
  run grep -q 'namespace: kargo' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}


# --- API ingress allow (Envoy Gateway → kargo-api TCP 80) -------------------------
@test "allow-kargo-api-from-gateway.yaml exists in kargo/networkpolicy/" {
  [ -f "$KARGO_NP/allow-kargo-api-from-gateway.yaml" ]
}

@test "kargo kustomization references the gateway ingress allow file" {
  run grep -q 'allow-kargo-api-from-gateway.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-api-from-gateway allows ingress on port 80" {
  run grep -q 'port: 80' "$KARGO_NP/allow-kargo-api-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-api-from-gateway restricts source to envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$KARGO_NP/allow-kargo-api-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-api-from-gateway uses Ingress policyType" {
  run grep -q 'Ingress' "$KARGO_NP/allow-kargo-api-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

# --- webhook allow (kube-apiserver → kargo webhooks TCP 9443) ---------------------
@test "allow-kargo-webhook-from-apiserver.yaml exists in kargo/networkpolicy/" {
  [ -f "$KARGO_NP/allow-kargo-webhook-from-apiserver.yaml" ]
}

@test "kargo kustomization references the webhook allow file" {
  run grep -q 'allow-kargo-webhook-from-apiserver.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-webhook-from-apiserver allows ingress on port 9443" {
  run grep -q 'port: "9443"' "$KARGO_NP/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# fromEntities remote-node, not ipBlock 10.43.0.1/32: k3s embeds the apiserver in
# the server node's own process, so its outbound webhook call carries Cilium's
# remote-node identity + the node's real pod-network IP as source — the apiserver
# Service ClusterIP is never the actual source address on an outbound connection,
# so an ipBlock rule against it silently never matches (verified live with
# `cilium monitor --type drop` while fixing the identical bug for ESO's webhook).
@test "allow-kargo-webhook-from-apiserver is a CiliumNetworkPolicy using fromEntities remote-node" {
  run grep -q 'kind: CiliumNetworkPolicy' "$KARGO_NP/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'remote-node' "$KARGO_NP/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-webhook-from-apiserver does not regress to the broken ipBlock 10.43.0.1 pattern" {
  run grep -q -- '- ipBlock:' "$KARGO_NP/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -ne 0 ]
}

# --- ArgoCD egress allow (kargo controller → argocd-server TCP 80) ----------------
@test "allow-kargo-egress-argocd.yaml exists in kargo/networkpolicy/" {
  [ -f "$KARGO_NP/allow-kargo-egress-argocd.yaml" ]
}

@test "kargo kustomization references the argocd egress allow file" {
  run grep -q 'allow-kargo-egress-argocd.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-egress-argocd uses Egress policyType" {
  run grep -q 'Egress' "$KARGO_NP/allow-kargo-egress-argocd.yaml"
  [ "$status" -eq 0 ]
}

# --- registry egress allow (kargo Warehouse → image registry TCP 443) ------------
@test "allow-kargo-egress-registry.yaml exists in kargo/networkpolicy/" {
  [ -f "$KARGO_NP/allow-kargo-egress-registry.yaml" ]
}

@test "kargo kustomization references the registry egress allow file" {
  run grep -q 'allow-kargo-egress-registry.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-egress-registry allows egress on port 443" {
  run grep -q 'port: 443' "$KARGO_NP/allow-kargo-egress-registry.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-egress-registry uses Egress policyType" {
  run grep -q 'Egress' "$KARGO_NP/allow-kargo-egress-registry.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-egress-registry keeps the existing legacy-registry namespaceSelector (additive, not a replacement)" {
  run grep -q 'kubernetes.io/metadata.name: artifactory' "$KARGO_NP/allow-kargo-egress-registry.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-egress-registry now also allows egress to the harbor namespace (auto/harbor-capstone-rewire prep)" {
  run grep -q 'kubernetes.io/metadata.name: harbor' "$KARGO_NP/allow-kargo-egress-registry.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → kargo pods TCP 8080) ----------------------------------
@test "allow-kargo-metrics-ingress.yaml exists in kargo/networkpolicy/" {
  [ -f "$KARGO_NP/allow-kargo-metrics-ingress.yaml" ]
}

@test "kargo kustomization references the metrics allow file" {
  run grep -q 'allow-kargo-metrics-ingress.yaml' "$KARGO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-metrics-ingress allows ingress on port 8080" {
  run grep -q 'port: 8080' "$KARGO_NP/allow-kargo-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-metrics-ingress restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$KARGO_NP/allow-kargo-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-metrics-ingress uses Ingress policyType" {
  run grep -q 'Ingress' "$KARGO_NP/allow-kargo-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-networkpolicy Application (wave 4, on-demand — no automated: block) ---
@test "kargo-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/kargo-networkpolicy.yaml" ]
}

@test "kargo-networkpolicy Application targets kargo namespace" {
  run grep -q 'namespace: kargo' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-networkpolicy Application sources from gitops/kargo/networkpolicy" {
  run grep -q 'gitops/kargo/networkpolicy' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
