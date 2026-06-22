#!/usr/bin/env bats
# Clusterless structural tests for the observability namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- observability namespace overlay (ADR-0016 §4 fan-out) -----------------------
@test "observability networkpolicy kustomization.yaml exists" {
  [ -f "$OBS_NP/kustomization.yaml" ]
}

@test "observability kustomization sets namespace: observability" {
  run grep -q 'namespace: observability' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "observability kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "observability kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$OBS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-grafana-ingress-from-gateway.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-grafana-ingress-from-gateway.yaml" ]
}

@test "allow-grafana-ingress-from-gateway allows TCP port 3000 (Grafana container port)" {
  run grep -q 'port: 3000' "$OBS_NP/allow-grafana-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-grafana-ingress-from-gateway allows ingress from envoy-gateway-system namespace" {
  run grep -q 'envoy-gateway-system' "$OBS_NP/allow-grafana-ingress-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-tempo-ingress-otlp.yaml" ]
}

@test "allow-tempo-ingress-otlp allows TCP port 4318 (OTLP HTTP)" {
  run grep -q 'port: 4318' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp allows ingress from capstone namespace" {
  run grep -q 'kubernetes.io/metadata.name: capstone' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-tempo-ingress-otlp allows ingress from lab-demo namespace" {
  run grep -q 'kubernetes.io/metadata.name: lab-demo' "$OBS_NP/allow-tempo-ingress-otlp.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external.yaml exists in observability/networkpolicy/" {
  [ -f "$OBS_NP/allow-alloy-egress-external.yaml" ]
}

@test "allow-alloy-egress-external covers argocd namespace" {
  run grep -q 'kubernetes.io/metadata.name: argocd' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external covers data namespace" {
  run grep -q 'kubernetes.io/metadata.name: data' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external covers kubelet port 10250 via cidr" {
  run grep -q 'port: 10250' "$OBS_NP/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-egress-storage.yaml allows TCP 3900 to storage namespace (Garage S3 backend)" {
  run grep -q 'port: 3900' "$OBS_NP/allow-egress-storage.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: storage' "$OBS_NP/allow-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application has automated sync enabled" {
  run grep -q 'automated:' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application uses LoadRestrictionsNone build option" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "observability-networkpolicy ArgoCD Application targets the observability namespace" {
  run grep -q 'destNamespace: observability' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
