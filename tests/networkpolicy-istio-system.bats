#!/usr/bin/env bats
# Clusterless structural tests for the istio-system namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Lives in its own per-scope file — NOT appended to the
# frozen tests/networkpolicy.bats monolith — so parallel NetworkPolicy fan-out
# PRs never collide at the monolith's EOF (the conflict that hit #247 vs #248).
# One scope = one file = no shared append anchor. See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "istio-system/networkpolicy/kustomization.yaml exists" {
  [ -f "$ISTIO_SYSTEM_NP/kustomization.yaml" ]
}

@test "istio-system networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$ISTIO_SYSTEM_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$ISTIO_SYSTEM_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-istio-intra-namespace.yaml exists" {
  [ -f "$ISTIO_SYSTEM_NP/allow-istio-intra-namespace.yaml" ]
}

@test "allow-istio-intra-namespace allows both Ingress and Egress" {
  run grep -c 'Ingress\|Egress' "$ISTIO_SYSTEM_NP/allow-istio-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-istio-intra-namespace uses empty podSelector (all pods in namespace)" {
  run grep -q 'podSelector: {}' "$ISTIO_SYSTEM_NP/allow-istio-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-istio-metrics-ingress.yaml exists" {
  [ -f "$ISTIO_SYSTEM_NP/allow-istio-metrics-ingress.yaml" ]
}

@test "allow-istio-metrics-ingress targets port 15014 (istiod Prometheus scrape port)" {
  run grep -q 'port: 15014' "$ISTIO_SYSTEM_NP/allow-istio-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-istio-metrics-ingress targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ISTIO_SYSTEM_NP/allow-istio-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'istio-system-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "istio-system-networkpolicy appset entry references gitops/istio-system/networkpolicy" {
  run grep -q 'gitops/istio-system/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# Kiali allows (RFC #288)
@test "allow-kiali-ingress.yaml exists" {
  [ -f "$ISTIO_SYSTEM_NP/allow-kiali-ingress.yaml" ]
}

@test "allow-kiali-ingress targets TCP 20001 (Kiali web UI port)" {
  run grep -q 'port: 20001' "$ISTIO_SYSTEM_NP/allow-kiali-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kiali-ingress targets the kube-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: kube-system' "$ISTIO_SYSTEM_NP/allow-kiali-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kiali-ingress scoped to kiali podSelector" {
  run grep -q 'app.kubernetes.io/name: kiali' "$ISTIO_SYSTEM_NP/allow-kiali-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kiali-observability-egress.yaml exists" {
  [ -f "$ISTIO_SYSTEM_NP/allow-kiali-observability-egress.yaml" ]
}

@test "allow-kiali-observability-egress targets TCP 9009 (Mimir Prometheus port)" {
  run grep -q 'port: 9009' "$ISTIO_SYSTEM_NP/allow-kiali-observability-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kiali-observability-egress targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$ISTIO_SYSTEM_NP/allow-kiali-observability-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kiali-observability-egress scoped to kiali podSelector" {
  run grep -q 'app.kubernetes.io/name: kiali' "$ISTIO_SYSTEM_NP/allow-kiali-observability-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "kustomization.yaml references allow-kiali-ingress.yaml" {
  run grep -q 'allow-kiali-ingress.yaml' "$ISTIO_SYSTEM_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kustomization.yaml references allow-kiali-observability-egress.yaml" {
  run grep -q 'allow-kiali-observability-egress.yaml' "$ISTIO_SYSTEM_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}
