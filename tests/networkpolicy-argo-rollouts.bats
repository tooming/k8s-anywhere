#!/usr/bin/env bats
# Clusterless structural tests for the argo-rollouts namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- argo-rollouts namespace overlay (ADR-0016 §4 fan-out, ADR-0020) --------------
@test "argo-rollouts networkpolicy kustomization.yaml exists" {
  [ -f "$ARGO_ROLLOUTS_NP/kustomization.yaml" ]
}

@test "argo-rollouts kustomization sets namespace: argo-rollouts" {
  run grep -q 'namespace: argo-rollouts' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts kustomization references the shared zz-dns-clusterip-bridge template" {
  run grep -q 'zz-dns-clusterip-bridge' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → Argo Rollouts TCP 8090) -------------------------------
@test "allow-argo-rollouts-metrics-from-observability.yaml exists in argo-rollouts/networkpolicy/" {
  [ -f "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-metrics-from-observability.yaml" ]
}

@test "argo-rollouts kustomization references the metrics allow file" {
  run grep -q 'allow-argo-rollouts-metrics-from-observability.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-metrics-from-observability allows ingress on port 8090" {
  run grep -q 'port: 8090' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-metrics-from-observability restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- dashboard allow (Envoy proxy → rollouts-dashboard TCP 3100) ------------------
@test "allow-argo-rollouts-dashboard-from-gateway.yaml exists in argo-rollouts/networkpolicy/" {
  [ -f "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-dashboard-from-gateway.yaml" ]
}

@test "argo-rollouts kustomization references the dashboard gateway allow file" {
  run grep -q 'allow-argo-rollouts-dashboard-from-gateway.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-dashboard-from-gateway allows ingress on port 3100" {
  run grep -q 'port: 3100' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-dashboard-from-gateway restricts source to envoy-gateway-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-dashboard-from-gateway restricts source to proxy component pods" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

# --- Mimir egress allow (Argo Rollouts → Mimir TCP 8080) --------------------------
@test "allow-argo-rollouts-egress-mimir.yaml exists in argo-rollouts/networkpolicy/" {
  [ -f "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-egress-mimir.yaml" ]
}

@test "argo-rollouts kustomization references the Mimir egress allow file" {
  run grep -q 'allow-argo-rollouts-egress-mimir.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-egress-mimir allows egress on port 8080" {
  run grep -q 'port: 8080' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-egress-mimir.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-egress-mimir uses Egress policyType" {
  run grep -q 'Egress' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-egress-mimir.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-egress-mimir targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-egress-mimir.yaml"
  [ "$status" -eq 0 ]
}

# --- plugin egress allow (controller → GitHub CDN TCP 443) -----------------------
@test "allow-argo-rollouts-controller-egress-plugins.yaml exists in argo-rollouts/networkpolicy/" {
  [ -f "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-controller-egress-plugins.yaml" ]
}

@test "argo-rollouts kustomization references the controller plugin-egress allow file" {
  run grep -q 'allow-argo-rollouts-controller-egress-plugins.yaml' "$ARGO_ROLLOUTS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-controller-egress-plugins allows egress on port 443" {
  run grep -q 'port: 443' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-controller-egress-plugins.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-controller-egress-plugins uses ipBlock for external CDN" {
  run grep -q 'ipBlock:' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-controller-egress-plugins.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-argo-rollouts-controller-egress-plugins scopes to rollouts-controller pods" {
  run grep -q 'app.kubernetes.io/component: rollouts-controller' "$ARGO_ROLLOUTS_NP/allow-argo-rollouts-controller-egress-plugins.yaml"
  [ "$status" -eq 0 ]
}

# --- argo-rollouts-networkpolicy Application (wave 4) ----------------------------
@test "argo-rollouts-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml" ]
}

@test "argo-rollouts-networkpolicy Application targets argo-rollouts namespace" {
  run grep -q 'namespace: argo-rollouts' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application sources from gitops/argo-rollouts/networkpolicy" {
  run grep -q 'gitops/argo-rollouts/networkpolicy' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
