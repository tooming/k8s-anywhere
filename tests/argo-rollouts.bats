#!/usr/bin/env bats
# Clusterless structural tests for Argo Rollouts (progressive delivery controller, ADR-0020).
# Validates GitOps wiring (Application shape, chart pin, plug-in install block),
# namespace PSA labels, HTTPRoute, NetworkPolicy overlay, Alloy scrape job, and
# Grafana dashboard — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
}

# --- ArgoCD Application shape (always-on, auto-synced) -----------------------
@test "argo-rollouts Application exists" {
  [ -f "$REPO/gitops/platform/argo-rollouts.yaml" ]
}

@test "argo-rollouts Application sources the chart from argoproj.github.io/argo-helm" {
  run grep -q 'repoURL: https://argoproj.github.io/argo-helm' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application pins a specific 2.40.x chart version" {
  run grep -qE 'targetRevision: 2\.40\.' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application targets the argo-rollouts namespace" {
  run grep -q 'namespace: argo-rollouts' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application declares the gatewayAPI traffic-router plugin" {
  run grep -q 'argoproj-labs/gatewayAPI' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application pins the gatewayAPI plugin at v0.5.0" {
  run grep -q 'v0.5.0' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts trafficRouterPlugins is a YAML list, not a string (else the controller crashloops)" {
  # A "|" block scalar double-encodes into the ConfigMap and the controller dies with
  # "cannot unmarshal string into Go value of type []types.PluginItem". Guard: it must
  # be a sequence. See scripts/rollouts-plugin-list-check.sh.
  [ "$(yqs '.spec.source.helm.valuesObject.controller.trafficRouterPlugins | tag' "$REPO/gitops/platform/argo-rollouts.yaml")" = "!!seq" ]
}

@test "argo-rollouts Application enables the dashboard" {
  run grep -q 'enabled: true' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application sets controller memory limit to 128Mi" {
  run grep -q 'memory: 128Mi' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application sets dashboard memory limit to 64Mi" {
  run grep -q 'memory: 64Mi' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

# --- argo-rollouts-extras (namespace + route pre-creation, wave 0) -----------
@test "argo-rollouts-extras Application exists" {
  [ -f "$REPO/gitops/platform/argo-rollouts-extras.yaml" ]
}

@test "argo-rollouts-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/argo-rollouts-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-extras sources the gitops/argo-rollouts git path" {
  run grep -q 'path: gitops/argo-rollouts' "$REPO/gitops/platform/argo-rollouts-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-extras is auto-synced" {
  run grep -q 'automated:' "$REPO/gitops/platform/argo-rollouts-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017: restricted, no carve-out needed) ---------
@test "argo-rollouts namespace manifest exists" {
  [ -f "$REPO/gitops/argo-rollouts/namespace.yaml" ]
}

@test "argo-rollouts namespace enforces PSA restricted (ADR-0017, no carve-out)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/argo-rollouts/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts namespace sets enforce-version to latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/argo-rollouts/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- HTTPRoute (rollouts.127.0.0.1.nip.io → dashboard :3100) -----------------
@test "argo-rollouts HTTPRoute file exists" {
  [ -f "$REPO/gitops/argo-rollouts/route.yaml" ]
}

@test "argo-rollouts HTTPRoute exposes rollouts.127.0.0.1.nip.io" {
  run grep -q 'rollouts.127.0.0.1.nip.io' "$REPO/gitops/argo-rollouts/route.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts HTTPRoute routes to the dashboard service on port 3100" {
  run grep -q 'port: 3100' "$REPO/gitops/argo-rollouts/route.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts HTTPRoute attaches to the lab-gateway Gateway" {
  run grep -q 'namespace: lab-gateway' "$REPO/gitops/argo-rollouts/route.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts HTTPRoute backend is the argo-rollouts-dashboard service" {
  run grep -q 'argo-rollouts-dashboard' "$REPO/gitops/argo-rollouts/route.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay structure (ADR-0016 §4 fan-out) -------------------
@test "argo-rollouts NetworkPolicy kustomization exists" {
  [ -f "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml" ]
}

@test "argo-rollouts NetworkPolicy kustomization references the default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts NetworkPolicy kustomization references the allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts NetworkPolicy kustomization references the metrics allow file" {
  run grep -q 'allow-argo-rollouts-metrics-from-observability.yaml' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts NetworkPolicy kustomization references the dashboard gateway allow file" {
  run grep -q 'allow-argo-rollouts-dashboard-from-gateway.yaml' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts NetworkPolicy kustomization references the Mimir egress allow file" {
  run grep -q 'allow-argo-rollouts-egress-mimir.yaml' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- Metrics ingress allow (Alloy → controller :8090) ------------------------
@test "metrics allow file exists" {
  [ -f "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-metrics-from-observability.yaml" ]
}

@test "metrics allow file opens TCP 8090" {
  run grep -q 'port: 8090' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "metrics allow file admits pods from the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- Dashboard ingress allow (Envoy proxy → dashboard :3100) -----------------
@test "dashboard gateway allow file exists" {
  [ -f "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml" ]
}

@test "dashboard allow file opens TCP 3100" {
  run grep -q 'port: 3100' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "dashboard allow file scopes ingress to envoy-gateway-system proxy pods" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

# --- Mimir egress allow (controller → Mimir query frontend :8080) -----------
@test "Mimir egress allow file exists" {
  [ -f "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-egress-mimir.yaml" ]
}

@test "Mimir egress allow file opens TCP 8080 toward observability" {
  run grep -q 'port: 8080' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-egress-mimir.yaml"
  [ "$status" -eq 0 ]
}

@test "Mimir egress allow file targets the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-egress-mimir.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy ArgoCD Application (wave 4) --------------------------------
@test "argo-rollouts-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml" ]
}

@test "argo-rollouts-networkpolicy Application runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts-networkpolicy Application is auto-synced" {
  run grep -q 'automated:' "$REPO/gitops/platform/argo-rollouts-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Grafana Lab UIs panel (stack-health.json drift check) --------------------
@test "stack-health.json Lab UIs panel lists the rollouts dashboard URL" {
  run grep -q 'rollouts.127.0.0.1.nip.io' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

# --- ADR documentation -------------------------------------------------------
@test "ADR-0020 (Argo Rollouts) document exists" {
  run sh -c "ls $REPO/docs/decisions/adr-0020-*.md"
  [ "$status" -eq 0 ]
}

# --- Alloy scrape job (metrics -> Mimir, deferred from controller PR) ---------
@test "observability-alloy.yaml contains argo_rollouts scrape job block" {
  run grep -q 'prometheus.scrape "argo_rollouts"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo_rollouts scrape job targets argo-rollouts-metrics service on :8090" {
  run grep -q 'argo-rollouts-metrics.argo-rollouts.svc.cluster.local:8090' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "argo_rollouts scrape job forwards to mimir remote_write receiver" {
  run grep -A5 'prometheus.scrape "argo_rollouts"' "$REPO/gitops/platform/observability-alloy.yaml"
  [[ "$output" == *"prometheus.remote_write.mimir.receiver"* ]]
}

# --- Grafana dashboard (lab-argo-rollouts.json, deferred from controller PR) --
@test "lab-argo-rollouts.json dashboard file exists" {
  [ -f "$REPO/grafana/dashboards/lab-argo-rollouts.json" ]
}

@test "lab-argo-rollouts.json uid matches file name convention" {
  run grep -q '"uid": "lab-argo-rollouts"' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json references controller_runtime_reconcile_total (real metric, ADR-0004)" {
  run grep -q 'controller_runtime_reconcile_total' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json references rollout_phase (real metric, ADR-0004)" {
  run grep -q 'rollout_phase' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json references rollout_canary_weight (real metric, ADR-0004)" {
  run grep -q 'rollout_canary_weight' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json uses mimir datasource uid (X-Scope-OrgID via datasource config)" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json contains no placeholder or fabricated data strings (ADR-0004)" {
  run grep -iE '"(placeholder|fabricated|dummy|fake|example_metric)"' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -ne 0 ]
}
