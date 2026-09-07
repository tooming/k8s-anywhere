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
  run grep -q 'port: 10250' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# Plain networking.k8s.io/v1 NetworkPolicy, ipBlock 0.0.0.0/0 scoped to TCP 10250 —
# Cilium (ADR-0014, `fromEntities: remote-node`) was removed entirely 2026-09-07,
# no replacement. k3s embeds the apiserver in the server node's own process, so its
# outbound webhook call carries the node's real pod-network IP as source, not the
# apiserver Service ClusterIP — an ipBlock rule scoped to that ClusterIP (the
# pre-Cilium pattern this file used before, and the actual live bug it fixed)
# silently never matches. Plain NetworkPolicy has no "remote-node" equivalent, and
# the node's real IP isn't practically pinnable from a Kustomize template, hence
# the broad-but-port-scoped 0.0.0.0/0 ipBlock (see the file's own header).
@test "allow-cert-manager-webhook-from-apiserver is a plain NetworkPolicy (Cilium removed 2026-09-07)" {
  run grep -q 'kind: NetworkPolicy' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kind: CiliumNetworkPolicy' "$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml"
  [ "$status" -eq 1 ]
}

@test "allow-cert-manager-webhook-from-apiserver does not regress to the broken ipBlock 10.43.0.1 ClusterIP pattern" {
  # Excludes comment lines: the header legitimately explains *why* the old
  # ipBlock:10.43.0.1 pattern was broken (history), which itself mentions the
  # string — only an actual ipBlock: cidr field matters here.
  run bash -c "grep -vE '^\s*#' '$CERT_MANAGER_NP/allow-cert-manager-webhook-from-apiserver.yaml' | grep -q '10.43.0.1'"
  [ "$status" -ne 0 ]
}

# --- metrics allow (Alloy → cert-manager TCP 9402) REMOVED 2026-09-06 (ADR-0041,
# observability stack removed with no replacement) ----------------------------
@test "allow-cert-manager-metrics-from-observability.yaml no longer exists (ADR-0041)" {
  [ ! -f "$CERT_MANAGER_NP/allow-cert-manager-metrics-from-observability.yaml" ]
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
