#!/usr/bin/env bats
# Clusterless structural tests for the inkless namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Lives in its own per-scope file — NOT appended to the
# frozen tests/networkpolicy.bats monolith — so parallel NetworkPolicy fan-out
# PRs never collide at the monolith's EOF (the conflict that hit #247 vs #248).
# One scope = one file = no shared append anchor. See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "inkless/networkpolicy/kustomization.yaml exists" {
  [ -f "$INKLESS_NP/kustomization.yaml" ]
}

@test "inkless networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$INKLESS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$INKLESS_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-inkless-intra-namespace.yaml exists" {
  [ -f "$INKLESS_NP/allow-inkless-intra-namespace.yaml" ]
}

@test "allow-inkless-intra-namespace allows both Ingress and Egress" {
  run grep -c 'Ingress\|Egress' "$INKLESS_NP/allow-inkless-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-inkless-intra-namespace uses empty podSelector (all pods in namespace)" {
  run grep -q 'podSelector: {}' "$INKLESS_NP/allow-inkless-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-inkless-garage-egress.yaml exists" {
  [ -f "$INKLESS_NP/allow-inkless-garage-egress.yaml" ]
}

@test "allow-inkless-garage-egress targets port 3900 (Garage S3)" {
  run grep -q 'port: 3900' "$INKLESS_NP/allow-inkless-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-inkless-garage-egress targets the storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' "$INKLESS_NP/allow-inkless-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-inkless-metrics-ingress.yaml exists" {
  [ -f "$INKLESS_NP/allow-inkless-metrics-ingress.yaml" ]
}

@test "allow-inkless-metrics-ingress targets port 9308 (Kafka exporter metrics)" {
  run grep -q 'port: 9308' "$INKLESS_NP/allow-inkless-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-inkless-metrics-ingress targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$INKLESS_NP/allow-inkless-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'inkless-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "inkless-networkpolicy appset entry references gitops/inkless/networkpolicy" {
  run grep -q 'gitops/inkless/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
