#!/usr/bin/env bats
# Clusterless structural tests for Trivy Operator (supply-chain CVE + SBOM scanner,
# ADR-0022, CHARTER O1). Validates GitOps wiring (Application shape, namespace PSA
# labels, NetworkPolicy overlay), the Alloy metrics scrape job, and scanner toggles —
# no running cluster required.

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

@test "trivy-operator Application pins chart version 0.34.0" {
  run grep -q 'targetRevision: 0.34.0' "$REPO/gitops/platform/trivy-operator.yaml"
  [ "$status" -eq 0 ]
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

@test "trivy-system allow-trivy-metrics-from-observability rule exists" {
  [ -f "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-metrics-from-observability.yaml" ]
}

@test "trivy-metrics allow rule permits ingress on TCP 8080" {
  run grep -q 'port: 8080' "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-metrics allow rule selects Alloy pods from observability namespace" {
  run grep -q 'app.kubernetes.io/name: alloy' "$REPO/gitops/trivy-system/networkpolicy/allow-trivy-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
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

# --- Alloy scrape job (ADR-0022 §Observability) --------------------------------
@test "observability-alloy has a trivy_operator scrape job" {
  run grep -q 'prometheus.scrape "trivy_operator"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "trivy-operator scrape targets trivy-system.svc on port 8080" {
  run grep -q 'trivy-operator.trivy-system.svc.cluster.local:8080' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-alloy-egress-external includes egress to trivy-system namespace" {
  run grep -q 'trivy-system' "$REPO/gitops/observability/networkpolicy/allow-alloy-egress-external.yaml"
  [ "$status" -eq 0 ]
}

# --- Grafana dashboard (ADR-0004: real metrics only) --------------------------
@test "lab-trivy.json dashboard exists in grafana/dashboards/" {
  [ -f "$REPO/grafana/dashboards/lab-trivy.json" ]
}

@test "lab-trivy.json references trivy_image_vulnerabilities (CVE-by-severity panels)" {
  run grep -q 'trivy_image_vulnerabilities' "$REPO/grafana/dashboards/lab-trivy.json"
  [ "$status" -eq 0 ]
}

@test "lab-trivy.json references trivy_sbom_reports_total (CHARTER supply-chain goal)" {
  run grep -q 'trivy_sbom_reports_total' "$REPO/grafana/dashboards/lab-trivy.json"
  [ "$status" -eq 0 ]
}

@test "lab-trivy.json references trivy_config_audit_checks_total (configAudit panel)" {
  run grep -q 'trivy_config_audit_checks_total' "$REPO/grafana/dashboards/lab-trivy.json"
  [ "$status" -eq 0 ]
}

@test "lab-trivy.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-trivy.json"
  [ "$status" -eq 1 ]
}

@test "lab-trivy.json uses Mimir datasource uid" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-trivy.json"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md Trivy note confirms dashboard is present" {
  run grep -q 'lab-trivy.json' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
