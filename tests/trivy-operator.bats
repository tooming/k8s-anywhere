#!/usr/bin/env bats
# Clusterless structural tests for Trivy Operator (supply-chain CVE + SBOM scanner,
# ADR-0022, CHARTER O1). Validates GitOps wiring (Application shape, namespace PSA
# labels, NetworkPolicy overlay) and scanner toggles — no running cluster required.
# The Alloy metrics scrape job and Grafana dashboard this file used to also test
# were removed 2026-09-06 (ADR-0041, observability stack removed with no replacement).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "trivy-operator Application exists" {
  [ -f "$REPO/gitops/platform/trivy-operator.yaml" ]
}

@test "trivy-operator Application sources the aqua chart from aquasecurity.github.io" {
  run grep -q 'repoURL: https://aquasecurity.github.io/helm-charts/' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator Application pins chart version 0.36.0" {
  run grep -q 'targetRevision: 0.36.0' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator Application does not pin the stale 0.35.0 or 0.34.0 chart" {
  run grep -q 'targetRevision: 0.35.0' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 0.34.0' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -ne 0 ]
}

@test "trivy-operator Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator Application targets the trivy-system namespace" {
  run grep -q 'namespace: trivy-system' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

# --- Scanner toggles (ADR-0022 §Decision) -------------------------------------
@test "trivy-operator enables vulnerability scanning" {
  run grep -q 'vulnerabilityScannerEnabled: true' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

# --- Scan-job concurrency cap (2026-08-07: 13+ concurrent scan pods observed
# during an on-demand-component teardown, compounding host CPU pressure) -------
@test "trivy-operator caps concurrent scan jobs (scanJobsConcurrentLimit set)" {
  run grep -qE '^ +scanJobsConcurrentLimit: [0-9]+$' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator scanJobsConcurrentLimit is low (<=3, below chart default of 10)" {
  limit="$(grep -oE '^ +scanJobsConcurrentLimit: [0-9]+$' "$REPO/gitops/platform/trivy-operator.yaml" | grep -oE '[0-9]+$')"
  [ -n "$limit" ]
  [ "$limit" -le 3 ]
}

@test "trivy-operator enables SBOM generation (CHARTER supply-chain goal)" {
  run grep -q 'sbomGeneration: true' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator enables config audit scanning" {
  run grep -q 'configAuditScannerEnabled: true' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator excludes kube-system kube-public kube-node-lease (ADR-0022 §Scope)" {
  run grep -q 'excludeNamespaces: kube-system,kube-public,kube-node-lease' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
}

# --- trivy-extras (namespace pre-creation, wave 0) ----------------------------
@test "trivy-extras Application exists" {
  [ -f "$REPO/gitops/platform/trivy-extras.yaml" ]
}

@test "trivy-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/trivy-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017: baseline carve-out) ----------------------
@test "trivy-system namespace manifest exists" {
  [ -f "$REPO/gitops/trivy-system/namespace.yaml" ]
}

@test "trivy-system namespace enforces PSA baseline (not restricted — scan-job carve-out)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$REPO/gitops/trivy-system/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system namespace has audit label" {
  run grep -q 'pod-security.kubernetes.io/audit: baseline' "$REPO/gitops/trivy-system/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 §4 fan-out) ------------------------------
@test "trivy-system networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/trivy-system/networkpolicy/kustomization.yaml" ]
}

@test "trivy-system networkpolicy overlay references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/trivy-system/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system networkpolicy overlay references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/trivy-system/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system allow-trivy-metrics-from-observability rule no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-metrics-from-observability.yaml" ]
}

@test "trivy-system allow-trivy-egress-vdb rule exists" {
  [ -f "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-egress-vdb.yaml" ]
}

@test "trivy-egress-vdb rule permits TCP 443 (vuln-DB pull from ghcr.io)" {
  run grep -q 'port: 443' "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-egress-vdb.yaml"
  [ "$status" -eq 0 ]
}

# --- trivy-system-networkpolicy Application (wave 4) -------------------------
@test "trivy-system-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/trivy-system-networkpolicy.yaml" ]
}

@test "trivy-system-networkpolicy Application runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-system-networkpolicy uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/trivy-system-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Alloy scrape job (ADR-0022 §Observability) + Grafana dashboard REMOVED
# 2026-09-06 (ADR-0041, observability stack removed with no replacement) --------
@test "grafana/dashboards/lab-trivy.json no longer exists (ADR-0041)" {
  [ ! -f "$REPO/grafana/dashboards/lab-trivy.json" ]
}

@test "docs/dependency-tree.md wave-0 row lists trivy-extras" {
  run grep -q 'trivy-extras (namespace PSA baseline labels' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
