#!/usr/bin/env bats
# Clusterless structural tests for the lab-demo namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Lives in its own per-scope file — NOT appended to the
# frozen tests/networkpolicy.bats monolith — so parallel NetworkPolicy fan-out
# PRs never collide at the monolith's EOF (the conflict that hit #247 vs #248).
# One scope = one file = no shared append anchor. See scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

@test "lab-demo/networkpolicy/kustomization.yaml exists" {
  [ -f "$LAB_DEMO_NP/kustomization.yaml" ]
}

@test "lab-demo networkpolicy overlay references default-deny.yaml baseline" {
  run grep -q 'default-deny.yaml' "$LAB_DEMO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-demo networkpolicy overlay references allow-dns-and-apiserver.yaml baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$LAB_DEMO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-demo-egress-tempo.yaml no longer exists (ADR-0041)" {
  [ ! -f "$LAB_DEMO_NP/allow-demo-egress-tempo.yaml" ]
}

@test "lab-demo-networkpolicy entry exists in networkpolicy-appset.yaml" {
  run grep -q 'lab-demo-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-demo-networkpolicy appset entry references gitops/apps/demo/networkpolicy" {
  run grep -q 'gitops/apps/demo/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}
