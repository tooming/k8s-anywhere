#!/usr/bin/env bats
# Clusterless structural tests for the envoy-gateway-system namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- envoy-gateway-system namespace overlay (ADR-0016 §4 fan-out, RFC #206) ---------
@test "envoy-gateway-system networkpolicy kustomization.yaml exists" {
  [ -f "$ENVOY_GW_NP/kustomization.yaml" ]
}

@test "envoy-gateway-system kustomization sets namespace: envoy-gateway-system" {
  run grep -q 'namespace: envoy-gateway-system' "$ENVOY_GW_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$ENVOY_GW_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$ENVOY_GW_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-controller-metrics-ingress.yaml exists in envoy-gateway-system/networkpolicy/" {
  [ -f "$ENVOY_GW_NP/allow-envoy-controller-metrics-ingress.yaml" ]
}

@test "allow-envoy-controller-metrics-ingress allows port 19001 (controller metrics)" {
  run grep -q 'port: 19001' "$ENVOY_GW_NP/allow-envoy-controller-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-controller-metrics-ingress allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ENVOY_GW_NP/allow-envoy-controller-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-controller-metrics-ingress targets controller pods by name label" {
  run grep -q 'app.kubernetes.io/name: envoy-gateway' "$ENVOY_GW_NP/allow-envoy-controller-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-metrics-ingress.yaml exists in envoy-gateway-system/networkpolicy/" {
  [ -f "$ENVOY_GW_NP/allow-envoy-proxy-metrics-ingress.yaml" ]
}

@test "allow-envoy-proxy-metrics-ingress allows port 19000 (proxy stats)" {
  run grep -q 'port: 19000' "$ENVOY_GW_NP/allow-envoy-proxy-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-metrics-ingress allows ingress from observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ENVOY_GW_NP/allow-envoy-proxy-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-metrics-ingress targets proxy pods by component label" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ENVOY_GW_NP/allow-envoy-proxy-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-listener-ingress.yaml exists in envoy-gateway-system/networkpolicy/" {
  [ -f "$ENVOY_GW_NP/allow-envoy-proxy-listener-ingress.yaml" ]
}

@test "allow-envoy-proxy-listener-ingress allows port 10080 (north-south listener)" {
  run grep -q 'port: 10080' "$ENVOY_GW_NP/allow-envoy-proxy-listener-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-listener-ingress uses an ipBlock for external traffic" {
  run grep -q 'ipBlock:' "$ENVOY_GW_NP/allow-envoy-proxy-listener-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-listener-ingress targets proxy pods by component label" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ENVOY_GW_NP/allow-envoy-proxy-listener-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-backend-egress.yaml exists in envoy-gateway-system/networkpolicy/" {
  [ -f "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml" ]
}

@test "allow-envoy-proxy-backend-egress uses Egress policyType" {
  run grep -q 'Egress' "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-backend-egress includes all thirteen backend namespaces" {
  run grep -c 'argocd\|capstone\|vault\|observability\|data\|storage\|moto\|ack-system\|argo-rollouts\|kyverno\|velero\|trivy-system\|harbor' \
    "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 13 ]
}

@test "allow-envoy-proxy-backend-egress includes the harbor namespace" {
  run grep -q '^\s*- harbor\s*$' "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-backend-egress uses matchExpressions operator In" {
  run grep -q 'operator: In' "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-backend-egress targets proxy pods by component label" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ENVOY_GW_NP/allow-envoy-proxy-backend-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml" ]
}

@test "envoy-gateway-system-networkpolicy Application targets envoy-gateway-system namespace" {
  run grep -q 'namespace: envoy-gateway-system' "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-networkpolicy Application sources from gitops/envoy-gateway-system/networkpolicy" {
  run grep -q 'gitops/envoy-gateway-system/networkpolicy' "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway-system-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/envoy-gateway-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- proxy <-> control-plane xDS (TCP 18000) ---------------------------------
# default-deny denies both directions, so the data-plane proxy's xDS stream to the
# control plane needs BOTH the proxy egress and the control-plane ingress opened, or
# the proxy never gets its config, fails its startup probe, and crashloops — taking
# the whole :8080 north-south data path (every lab UI) down.
@test "allow-envoy-proxy-xds-egress.yaml exists and is in the kustomization" {
  [ -f "$ENVOY_GW_NP/allow-envoy-proxy-xds-egress.yaml" ]
  run grep -q 'allow-envoy-proxy-xds-egress.yaml' "$ENVOY_GW_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-proxy-xds-egress opens proxy egress to the control plane on 18000" {
  run grep -q 'app.kubernetes.io/component: proxy' "$ENVOY_GW_NP/allow-envoy-proxy-xds-egress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'control-plane: envoy-gateway' "$ENVOY_GW_NP/allow-envoy-proxy-xds-egress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: 18000' "$ENVOY_GW_NP/allow-envoy-proxy-xds-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-controller-xds-ingress.yaml exists and is in the kustomization" {
  [ -f "$ENVOY_GW_NP/allow-envoy-controller-xds-ingress.yaml" ]
  run grep -q 'allow-envoy-controller-xds-ingress.yaml' "$ENVOY_GW_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-envoy-controller-xds-ingress opens control-plane ingress from the proxy on 18000" {
  # Must select the control plane by control-plane=envoy-gateway (its
  # app.kubernetes.io/name is gateway-helm, so a name-based selector would miss it).
  run grep -q 'control-plane: envoy-gateway' "$ENVOY_GW_NP/allow-envoy-controller-xds-ingress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'app.kubernetes.io/component: proxy' "$ENVOY_GW_NP/allow-envoy-controller-xds-ingress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: 18000' "$ENVOY_GW_NP/allow-envoy-controller-xds-ingress.yaml"
  [ "$status" -eq 0 ]
}
