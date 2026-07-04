#!/usr/bin/env bats
# Clusterless structural tests for the velero namespace NetworkPolicy overlay
# (ADR-0016 §4 fan-out). Per-scope file — NOT part of the shared
# tests/networkpolicy.bats baseline — so parallel fan-out PRs never collide at a
# shared EOF (the #247 vs #248 conflict). Shared overlay paths come from
# tests/lib/networkpolicy-paths.bash. Guard: scripts/networkpolicy-tests-check.sh.

setup() {
  load lib/networkpolicy-paths
}

# --- velero namespace overlay (ADR-0016 §4 fan-out, ADR-0021) --------------------
@test "velero networkpolicy kustomization.yaml exists" {
  [ -f "$VELERO_NP/kustomization.yaml" ]
}

@test "velero kustomization sets namespace: velero" {
  run grep -q 'namespace: velero' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "velero kustomization references the shared default-deny template" {
  run grep -q 'network/policies/default-deny.yaml' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "velero kustomization references the shared allow-dns-and-apiserver template" {
  run grep -q 'network/policies/allow-dns-and-apiserver.yaml' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "velero kustomization references the shared zz-dns-clusterip-bridge template" {
  run grep -q 'zz-dns-clusterip-bridge' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- metrics allow (Alloy → Velero TCP 8085) --------------------------------------
@test "allow-velero-metrics-from-observability.yaml exists in velero/networkpolicy/" {
  [ -f "$VELERO_NP/allow-velero-metrics-from-observability.yaml" ]
}

@test "velero kustomization references the metrics allow file" {
  run grep -q 'allow-velero-metrics-from-observability.yaml' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-metrics-from-observability allows ingress on port 8085" {
  run grep -q 'port: 8085' "$VELERO_NP/allow-velero-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-metrics-from-observability restricts source to observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$VELERO_NP/allow-velero-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-metrics-from-observability restricts source to alloy pods" {
  run grep -q 'app.kubernetes.io/name: alloy' "$VELERO_NP/allow-velero-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage S3 egress allow (Velero → Garage TCP 3900) ---------------------------
@test "allow-velero-egress-storage.yaml exists in velero/networkpolicy/" {
  [ -f "$VELERO_NP/allow-velero-egress-storage.yaml" ]
}

@test "velero kustomization references the storage egress allow file" {
  run grep -q 'allow-velero-egress-storage.yaml' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-storage allows egress on port 3900 (Garage S3 API)" {
  run grep -q 'port: 3900' "$VELERO_NP/allow-velero-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-storage uses Egress policyType" {
  run grep -q 'Egress' "$VELERO_NP/allow-velero-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-storage targets the storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' "$VELERO_NP/allow-velero-egress-storage.yaml"
  [ "$status" -eq 0 ]
}

# --- Kopia PV egress allow (Velero → stateful namespaces) -------------------------
@test "allow-velero-egress-kopia-pv.yaml exists in velero/networkpolicy/" {
  [ -f "$VELERO_NP/allow-velero-egress-kopia-pv.yaml" ]
}

@test "velero kustomization references the Kopia PV egress allow file" {
  run grep -q 'allow-velero-egress-kopia-pv.yaml' "$VELERO_NP/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-kopia-pv covers the data namespace" {
  run grep -q -- '- data' "$VELERO_NP/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-kopia-pv covers the tidb namespace" {
  run grep -q -- '- tidb' "$VELERO_NP/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-kopia-pv covers the capstone namespace" {
  run grep -q -- '- capstone' "$VELERO_NP/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-kopia-pv covers the vault namespace" {
  run grep -q -- '- vault' "$VELERO_NP/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-velero-egress-kopia-pv uses Egress policyType" {
  run grep -q 'Egress' "$VELERO_NP/allow-velero-egress-kopia-pv.yaml"
  [ "$status" -eq 0 ]
}

# --- velero-networkpolicy Application (wave 4) ------------------------------------
@test "velero-networkpolicy Application file exists" {
  [ -f "$REPO/gitops/platform/velero-networkpolicy.yaml" ]
}

@test "velero-networkpolicy Application targets velero namespace" {
  run grep -q 'namespace: velero' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-networkpolicy Application sources from gitops/velero/networkpolicy" {
  run grep -q 'gitops/velero/networkpolicy' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-networkpolicy Application has automated sync" {
  run grep -q 'automated:' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-networkpolicy Application has LoadRestrictionsNone buildOption" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "velero-networkpolicy Application is at sync-wave 4" {
  run grep -q 'sync-wave: "4"' "$REPO/gitops/platform/velero-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}
