#!/usr/bin/env bats
# Clusterless structural tests for the cert-manager namespace NetworkPolicy
# overlay (ADR-0016 §4 fan-out, ADR-0028). Per-scope file — NOT part of the
# shared tests/networkpolicy.bats baseline — so parallel fan-out PRs never
# collide at a shared EOF (the #247 vs #248 conflict). Shared overlay paths
# come from tests/lib/networkpolicy-paths.bash. Guard:
# scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- cert-manager namespace overlay (ADR-0016 §4 fan-out, ADR-0028) ----------
@test "cert-manager networkpolicy kustomization.yaml exists" {
  [ -f "$CERT_MANAGER_NP/kustomization.yaml" ]
}

@test "cert-manager kustomization sets namespace: cert-manager" {
  run grep -q 'namespace: cert-manager' "$CERT_MANAGER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$CERT_MANAGER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$CERT_MANAGER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- webhook allow (kube-apiserver → cert-manager TCP 10250) -----------------
@test "allow-cert-manager-webhook-from-apiserver.yaml exists in cert-manager/networkpolicy/" {
  [ -f "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml" ]
}

@test "cert-manager kustomization references the webhook allow file" {
  run grep -q 'allow-cert-manager-webhook-from-apiserver.yaml' "$CERT_MANAGER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-cert-manager-webhook-from-apiserver allows ingress on port 10250" {
  run grep -q 'port: "10250"' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# fromEntities remote-node, not ipBlock 10.43.0.1/32: k3s embeds the apiserver in
# the server node's own process, so its outbound webhook call carries Cilium's
# remote-node identity + the node's real pod-network IP as source — the apiserver
# Service ClusterIP is never the actual source address on an outbound connection,
# so an ipBlock rule against it silently never matches (verified live with
# `cilium monitor --type drop` while fixing the identical bug for ESO's webhook).
@test "allow-cert-manager-webhook-from-apiserver is a CiliumNetworkPolicy using fromEntities remote-node" {
  run grep -q 'kind: CiliumNetworkPolicy' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'remote-node' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-cert-manager-webhook-from-apiserver does not regress to the broken ipBlock 10.43.0.1 pattern" {
  run grep -q -- '- ipBlock:' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -ne 0 ]
}

# --- metrics allow (Alloy → cert-manager TCP 9402) ----------------------------
@test "allow-cert-manager-metrics-from-observability.yaml exists in cert-manager/networkpolicy/" {
  [ -f "$CERT_MANAGER_NP/allow-cert-manager-metrics-from-observability.yaml" ]
}

@test "cert-manager kustomization references the metrics allow file" {
  run grep -q 'allow-cert-manager-metrics-from-observability.yaml' "$CERT_MANAGER_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-cert-manager-metrics-from-observability allows ingress on port 9402" {
  run grep -q 'port: 9402' "$CERT_MANAGER_NP/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-cert-manager-metrics-from-observability restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$CERT_MANAGER_NP/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-cert-manager-metrics-from-observability restricts source to alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$CERT_MANAGER_NP/allow-cert-manager-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- cert-manager-networkpolicy Application (wave 4) --------------------------
@test "cert-manager-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/cert-manager-networkpolicy.yaml" ]
}

@test "cert-manager-networkpolicy Application targets cert-manager namespace" {
  run grep -q 'namespace: cert-manager' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy Application sources from gitops/cert-manager/networkpolicy" {
  run grep -q 'gitops/cert-manager/networkpolicy' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "cert-manager-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/cert-manager-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
