#!/usr/bin/env bats
# Clusterless structural tests for the longhorn-system namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, ROADMAP auto/pss-np-longhorn). Lives in its own per-scope
# file — NOT appended to the frozen tests/networkpolicy.bats monolith — so parallel
# NetworkPolicy fan-out PRs never collide at the monolith's EOF (the conflict that
# hit #247 vs #248). One scope = one file = no shared append anchor.
# See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "longhorn/networkpolicy/kustomization.yaml exists" {
  [ -f "$LONGHORN_NP/kustomization.yaml" ]
}

@test "longhorn networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$LONGHORN_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "longhorn networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$LONGHORN_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-longhorn-intra-namespace.yaml exists" {
  [ -f "$LONGHORN_NP/allow-longhorn-intra-namespace.yaml" ]
}

@test "allow-longhorn-intra-namespace allows both Ingress and Egress" {
  run grep -c 'Ingress\|Egress' "$LONGHORN_NP/allow-longhorn-intra-namespace.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "allow-longhorn-intra-namespace uses empty podSelector (all pods in namespace)" {
  run grep -q 'podSelector: {}' "$LONGHORN_NP/allow-longhorn-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-longhorn-metrics-ingress.yaml exists" {
  [ -f "$LONGHORN_NP/allow-longhorn-metrics-ingress.yaml" ]
}

@test "allow-longhorn-metrics-ingress targets port 9500 (Longhorn metrics)" {
  run grep -q 'port: 9500' "$LONGHORN_NP/allow-longhorn-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-longhorn-metrics-ingress targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$LONGHORN_NP/allow-longhorn-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "longhorn-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'longhorn-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "longhorn-networkpolicy appset entry references gitops/longhorn/networkpolicy" {
  run grep -q 'gitops/longhorn/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
