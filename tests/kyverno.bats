#!/usr/bin/env bats
# Clusterless structural tests for Kyverno (admission policy engine, ADR-0019).
# Validates GitOps wiring (Application shape, namespace PSA labels, NetworkPolicy
# overlay), the Alloy metrics scrape job, and the Grafana dashboard — no running
# cluster required. Companion to tests/networkpolicy.bats (which covers the
# default-deny fan-out) and the auto/kyverno-engine PR's manifests.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "kyverno Application exists" {
  [ -f "$REPO/gitops/platform/kyverno.yaml" ]
}

@test "kyverno Application sources the kyverno chart from kyverno.github.io" {
  run grep -q 'repoURL: https://kyverno.github.io/kyverno/' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application pins chart version 3.3.4" {
  run grep -q 'targetRevision: 3.3.4' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application targets the kyverno namespace" {
  run grep -q 'namespace: kyverno' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

# --- kyverno-extras (namespace pre-creation, wave 0) -------------------------
@test "kyverno-extras Application exists" {
  [ -f "$REPO/gitops/platform/kyverno-extras.yaml" ]
}

@test "kyverno-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/kyverno-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017 carve-out: baseline) ---------------------
@test "kyverno namespace manifest exists" {
  [ -f "$REPO/gitops/kyverno/namespace.yaml" ]
}

@test "kyverno namespace enforces PSA baseline (ADR-0017 carve-out)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay structure (ADR-0016 §4 fan-out) -------------------
@test "kyverno NetworkPolicy kustomization references the default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the webhook allow file" {
  run grep -q 'allow-kyverno-webhook-from-apiserver.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the metrics allow file" {
  run grep -q 'allow-kyverno-metrics-from-observability.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- Webhook allow rule (apiserver -> admission webhook :9443) ----------------
@test "webhook allow file opens TCP 9443" {
  run grep -q 'port: 9443' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "webhook allow file scopes ingress to the apiserver ipBlock" {
  run grep -q 'ipBlock:' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# --- Metrics allow rule (observability Alloy -> metrics :8000) ----------------
@test "metrics allow file opens TCP 8000" {
  run grep -q 'port: 8000' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "metrics allow file admits the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- Alloy scrape job --------------------------------------------------------
@test "Alloy has a kyverno scrape job" {
  run grep -q 'prometheus.scrape "kyverno"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "Alloy kyverno scrape targets a kyverno metrics Service on :8000" {
  run grep -qE 'kyverno-.*-controller-metrics\.kyverno\.svc\.cluster\.local:8000' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- Grafana dashboard (ADR-0004 real metrics) -------------------------------
@test "Grafana dashboard file lab-kyverno.json exists" {
  [ -f "$REPO/grafana/dashboards/lab-kyverno.json" ]
}

@test "lab-kyverno.json is valid JSON" {
  if ! command -v python3 >/dev/null 2>&1; then skip "python3 not installed"; fi
  run python3 -c "import json,sys; json.load(open('$REPO/grafana/dashboards/lab-kyverno.json'))"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json uid is lab-kyverno" {
  run grep -q '"uid": "lab-kyverno"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json has a stat-row pod-running panel" {
  run grep -q 'kube_pod_status_phase{namespace=\\"kyverno\\"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json charts kyverno_policy_results_total by validation/background mode" {
  run grep -q 'kyverno_policy_results_total' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
  run grep -q 'policy_validation_mode' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json charts admission review p95 latency" {
  run grep -q 'kyverno_admission_review_duration_seconds_bucket' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json filters policy execution results to non-pass" {
  run grep -q 'rule_result!=\\"pass\\"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

# --- ADR documentation -------------------------------------------------------
@test "ADR-0019 (Kyverno) document exists" {
  run sh -c "ls $REPO/docs/decisions/adr-0019-*.md"
  [ "$status" -eq 0 ]
}
