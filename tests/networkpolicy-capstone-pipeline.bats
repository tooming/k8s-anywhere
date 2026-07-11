#!/usr/bin/env bats
# Clusterless structural tests for the capstone-pipeline namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out, ADR-0023). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF. Shared overlay paths come from tests/lib/networkpolicy-paths.bash.
# Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- capstone-pipeline namespace overlay (ADR-0016 §4 fan-out, ADR-0023) -----------

@test "kargo-project/networkpolicy/kustomization.yaml exists" {
  [ -f "$KARGO_PROJECT_NP/kustomization.yaml" ]
}

@test "capstone-pipeline kustomization sets namespace: capstone-pipeline" {
  run grep -q 'namespace: capstone-pipeline' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline kustomization references the shared zz-dns-clusterip-bridge template" {
  run grep -q 'network/policies/zz-dns-clusterip-bridge.yaml' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo egress allow (promotion pods → kargo controller/api) -------------------

@test "allow-capstone-pipeline-egress-kargo.yaml exists in kargo-project/networkpolicy/" {
  [ -f "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-kargo.yaml" ]
}

@test "capstone-pipeline kustomization references the kargo egress allow file" {
  run grep -q 'allow-capstone-pipeline-egress-kargo.yaml' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-pipeline-egress-kargo uses Egress policyType" {
  run grep -q 'Egress' "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-pipeline-egress-kargo targets kargo namespace" {
  run grep -q 'kubernetes.io/metadata.name: kargo' "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-kargo.yaml"
  [ "$status" -eq 0 ]
}

# --- argocd egress allow (promotion pods → argocd-server TCP 80 for argocd-update) -

@test "allow-capstone-pipeline-egress-argocd.yaml exists in kargo-project/networkpolicy/" {
  [ -f "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-argocd.yaml" ]
}

@test "capstone-pipeline kustomization references the argocd egress allow file" {
  run grep -q 'allow-capstone-pipeline-egress-argocd.yaml' "$KARGO_PROJECT_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-pipeline-egress-argocd uses Egress policyType" {
  run grep -q 'Egress' "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-argocd.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-pipeline-egress-argocd allows egress to port 80" {
  run grep -q 'port: 80' "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-argocd.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-capstone-pipeline-egress-argocd targets argocd namespace" {
  run grep -q 'kubernetes.io/metadata.name: argocd' "$KARGO_PROJECT_NP/allow-capstone-pipeline-egress-argocd.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-project-networkpolicy Application (wave 4, on-demand — no automated: block) -

@test "kargo-project-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/kargo-project-networkpolicy.yaml" ]
}

@test "kargo-project-networkpolicy Application targets capstone-pipeline namespace" {
  run grep -q 'namespace: capstone-pipeline' "$REPO/gitops/platform/kargo-project-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project-networkpolicy Application sources from gitops/kargo-project/networkpolicy" {
  run grep -q 'gitops/kargo-project/networkpolicy' "$REPO/gitops/platform/kargo-project-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/kargo-project-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/kargo-project-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project-networkpolicy Application has no automated sync block (on-demand)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-project-networkpolicy.yaml"
  [ "$status" -ne 0 ]
}
