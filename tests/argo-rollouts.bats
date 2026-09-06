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

@test "argo-rollouts Application pins a specific chart version" {
  run grep -qE 'targetRevision: [0-9]+\.[0-9]+\.[0-9]+' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application chart pin is at least 2.43.0 (appVersion v1.10.0 currency bump, ADR-0020)" {
  run grep -q 'targetRevision: 2.43.0' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application does not pin the pre-bump 2.41.1 or 2.41.0 versions" {
  run grep -q 'targetRevision: 2.41.1' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 2.41.0' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -ne 0 ]
}

@test "argo-rollouts Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application targets the argo-rollouts namespace" {
  run grep -q 'namespace: argo-rollouts' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts Application no longer declares a traffic-router plugin (Traefik is built into core, ADR-0040)" {
  run grep -q 'name: argoproj-labs/gatewayAPI' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -ne 0 ]
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

# --- Dashboard PSA restricted compliance (ADR-0017) --------------------------
# Found live 2026-08-19 (#633 verification): the chart's top-level
# containerSecurityContext default (restricted-compliant) is NOT inherited by
# dashboard.* -- that sub-block has its own empty {} default -- so the
# dashboard Deployment was rejected by PSA admission for 26 days straight
# (0/1 available since the Application was first created 2026-07-24) until
# this was set explicitly. See gitops/platform/argo-rollouts.yaml's comment.
@test "argo-rollouts dashboard sets its own containerSecurityContext (chart does not inherit the top-level default)" {
  [ "$(yqs '.spec.source.helm.valuesObject.dashboard.containerSecurityContext.allowPrivilegeEscalation' "$REPO/gitops/platform/argo-rollouts.yaml")" = "false" ]
}

@test "argo-rollouts dashboard containerSecurityContext drops all capabilities" {
  [ "$(yqs '.spec.source.helm.valuesObject.dashboard.containerSecurityContext.capabilities.drop[0]' "$REPO/gitops/platform/argo-rollouts.yaml")" = "ALL" ]
}

# --- Image tag (CVE-2026-35469, RFC #552 -> chart bump, ADR-0020 Re-evaluation log) ---
# RFC #552 (2026-07-19) pinned controller/dashboard image.tag to "v1.9.1"
# explicitly, as a stopgap while argo-helm hadn't yet published a chart release
# tracking that appVersion. Once argo-rollouts-2.41.1 shipped tracking
# appVersion v1.9.1 (upgrade-drafter, 2026-07-20), the chart's own default
# already resolves to the fixed version, so the explicit override was removed
# as redundant -- the chart-pin assertion above is now the CVE-2026-35469
# recurrence guard instead of an image.tag assertion.
@test "argo-rollouts Application does not carry a redundant image.tag override (chart default now tracks the fix)" {
  run yqs '.spec.source.helm.valuesObject.controller.image.tag' "$REPO/gitops/platform/argo-rollouts.yaml"
  [ "$status" -ne 0 ] || [ "$output" = "null" ]
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

# --- IngressRoute (rollouts.127.0.0.1.nip.io → dashboard :3100, ADR-0040) ----
@test "argo-rollouts IngressRoute file exists" {
  [ -f "$REPO/gitops/argo-rollouts/ingressroute.yaml" ]
}

@test "argo-rollouts IngressRoute exposes rollouts.127.0.0.1.nip.io" {
  run grep -q 'rollouts.127.0.0.1.nip.io' "$REPO/gitops/argo-rollouts/ingressroute.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts IngressRoute routes to the dashboard service on port 3100" {
  run grep -q 'port: 3100' "$REPO/gitops/argo-rollouts/ingressroute.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts IngressRoute is a traefik.io/v1alpha1 object" {
  run grep -q 'apiVersion: traefik.io/v1alpha1' "$REPO/gitops/argo-rollouts/ingressroute.yaml"
  [ "$status" -eq 0 ]
}

@test "argo-rollouts IngressRoute backend is the argo-rollouts-dashboard service" {
  run grep -q 'argo-rollouts-dashboard' "$REPO/gitops/argo-rollouts/ingressroute.yaml"
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

# --- Controller plugin-download egress REMOVED 2026-09-06 (ADR-0040, supersedes
# Envoy Gateway/ADR-0008): the controller no longer downloads any traffic-router
# plugin binary at boot — Traefik's traffic routing is built into Argo Rollouts
# core (see gitops/apps/capstone/rollout.yaml's trafficRouting.traefik).
@test "argo-rollouts NetworkPolicy kustomization no longer references a controller plugin-egress allow file" {
  run grep -q '^  - allow-argo-rollouts-controller-egress-plugins.yaml$' "$REPO/gitops/argo-rollouts/networkpolicy/kustomization.yaml"
  [ "$status" -ne 0 ]
}

@test "controller plugin-egress allow file no longer exists" {
  [ ! -f "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-controller-egress-plugins.yaml" ]
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

# --- Dashboard ingress allow (Traefik → dashboard :3100) -----------------
@test "dashboard gateway allow file exists" {
  [ -f "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml" ]
}

@test "dashboard allow file opens TCP 3100" {
  run grep -q 'port: 3100' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "dashboard allow file scopes ingress to Traefik pods in kube-system" {
  run grep -q 'kubernetes.io/metadata.name: kube-system' "$REPO/gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml"
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

@test "lab-argo-rollouts.json does not reference the nonexistent rollout_canary_weight metric (2026-08-12: no such metric exists at pinned appVersion v1.9.1; panel removed rather than left permanently broken)" {
  run grep -q 'rollout_canary_weight' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 1 ]
}

@test "lab-argo-rollouts.json uses mimir datasource uid (X-Scope-OrgID via datasource config)" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -eq 0 ]
}

@test "lab-argo-rollouts.json contains no placeholder or fabricated data strings (ADR-0004)" {
  run grep -iE '"(placeholder|fabricated|dummy|fake|example_metric)"' "$REPO/grafana/dashboards/lab-argo-rollouts.json"
  [ "$status" -ne 0 ]
}
