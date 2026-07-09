#!/usr/bin/env bats
# Clusterless structural tests for the kyverno namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- kyverno namespace overlay (ADR-0016 §4 fan-out, ADR-0019) --------------------
@test "kyverno networkpolicy kustomization.yaml exists" {
  [ -f "$KYVERNO_NP/kustomization.yaml" ]
}

@test "kyverno kustomization sets namespace: kyverno" {
  run grep -q 'namespace: kyverno' "$KYVERNO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$KYVERNO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$KYVERNO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}


# --- webhook allow (kube-apiserver → Kyverno TCP 9443) ----------------------------
@test "allow-kyverno-webhook-from-apiserver.yaml exists in kyverno/networkpolicy/" {
  [ -f "$KYVERNO_NP/allow-kyverno-webhook-from-apiserver.yaml" ]
}

@test "kyverno kustomization references the webhook allow file" {
  run grep -q 'allow-kyverno-webhook-from-apiserver.yaml' "$KYVERNO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-webhook-from-apiserver allows ingress on port 9443" {
  run grep -q 'port: 9443' "$KYVERNO_NP/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-webhook-from-apiserver uses ipBlock for the kube-apiserver source" {
  run grep -q 'ipBlock:' "$KYVERNO_NP/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-webhook-from-apiserver uses Ingress policyType" {
  run grep -q 'Ingress' "$KYVERNO_NP/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → Kyverno TCP 8000) -------------------------------------
@test "allow-kyverno-metrics-from-observability.yaml exists in kyverno/networkpolicy/" {
  [ -f "$KYVERNO_NP/allow-kyverno-metrics-from-observability.yaml" ]
}

@test "kyverno kustomization references the metrics allow file" {
  run grep -q 'allow-kyverno-metrics-from-observability.yaml' "$KYVERNO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-metrics-from-observability allows ingress on port 8000" {
  run grep -q 'port: 8000' "$KYVERNO_NP/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-metrics-from-observability restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$KYVERNO_NP/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kyverno-metrics-from-observability restricts source to alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$KYVERNO_NP/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- kyverno-networkpolicy Application (wave 4) -----------------------------------
@test "kyverno-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/kyverno-networkpolicy.yaml" ]
}

@test "kyverno-networkpolicy Application targets kyverno namespace" {
  run grep -q 'namespace: kyverno' "$REPO/gitops/platform/kyverno-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-networkpolicy Application sources from gitops/kyverno/networkpolicy" {
  run grep -q 'gitops/kyverno/networkpolicy' "$REPO/gitops/platform/kyverno-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/kyverno-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/kyverno-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/kyverno-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
