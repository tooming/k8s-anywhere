#!/usr/bin/env bats
# Clusterless structural tests for the trivy-system namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- trivy-system namespace overlay (ADR-0016 §4 fan-out, ADR-0022) --------------
@test "trivy-system networkpolicy kustomization.yaml exists" {
  [ -f "$TRIVY_NP/kustomization.yaml" ]
}

@test "trivy-system kustomization sets namespace: trivy-system" {
  run grep -q 'namespace: trivy-system' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system kustomization references the shared zz-dns-clusterip-bridge template" {
  run grep -q 'zz-dns-clusterip-bridge' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → Trivy Operator TCP 8080) -----------------------------
@test "allow-trivy-metrics-from-observability.yaml exists in trivy-system/networkpolicy/" {
  [ -f "$TRIVY_NP/allow-trivy-metrics-from-observability.yaml" ]
}

@test "trivy-system kustomization references the metrics allow file" {
  run grep -q 'allow-trivy-metrics-from-observability.yaml' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-metrics-from-observability allows ingress on port 8080" {
  run grep -q 'port: 8080' "$TRIVY_NP/allow-trivy-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-metrics-from-observability restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$TRIVY_NP/allow-trivy-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-metrics-from-observability restricts source to alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$TRIVY_NP/allow-trivy-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- vuln-DB egress allow (Trivy → ghcr.io TCP 443) ------------------------------
@test "allow-trivy-egress-vdb.yaml exists in trivy-system/networkpolicy/" {
  [ -f "$TRIVY_NP/allow-trivy-egress-vdb.yaml" ]
}

@test "trivy-system kustomization references the vuln-DB egress allow file" {
  run grep -q 'allow-trivy-egress-vdb.yaml' "$TRIVY_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-egress-vdb allows egress on port 443 (ghcr.io vuln-DB pull)" {
  run grep -q 'port: 443' "$TRIVY_NP/allow-trivy-egress-vdb.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-egress-vdb uses ipBlock for external registry traffic" {
  run grep -q 'ipBlock:' "$TRIVY_NP/allow-trivy-egress-vdb.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-trivy-egress-vdb uses Egress policyType" {
  run grep -q 'Egress' "$TRIVY_NP/allow-trivy-egress-vdb.yaml"
  [ "$status" -eq 0 ]
}

# --- trivy-system-networkpolicy Application (wave 4) -----------------------------
@test "trivy-system-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/trivy-system-networkpolicy.yaml" ]
}

@test "trivy-system-networkpolicy Application targets trivy-system namespace" {
  run grep -q 'namespace: trivy-system' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system-networkpolicy Application sources from gitops/trivy-system/networkpolicy" {
  run grep -q 'gitops/trivy-system/networkpolicy' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
