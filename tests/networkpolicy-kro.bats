#!/usr/bin/env bats
# Clusterless structural tests for the kro namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Lives in its own per-scope file — NOT appended to the
# frozen tests/networkpolicy.bats monolith — so parallel NetworkPolicy fan-out
# PRs never collide at the monolith's EOF (the conflict that hit #247 vs #248).
# One scope = one file = no shared append anchor. See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "kro/networkpolicy/kustomization.yaml exists" {
  [ -f "$KRO_NP/kustomization.yaml" ]
}

@test "kro networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$KRO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kro networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$KRO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kro-ack-egress.yaml exists in kro/networkpolicy/" {
  [ -f "$KRO_NP/allow-kro-ack-egress.yaml" ]
}

@test "allow-kro-ack-egress uses Egress policyType" {
  run grep -q 'Egress' "$KRO_NP/allow-kro-ack-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kro-ack-egress targets ack-system namespace" {
  run grep -q 'kubernetes.io/metadata.name: ack-system' "$KRO_NP/allow-kro-ack-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "kro-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'kro-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "kro-networkpolicy appset entry references gitops/kro/networkpolicy" {
  run grep -q 'gitops/kro/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
