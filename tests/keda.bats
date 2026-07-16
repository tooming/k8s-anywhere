#!/usr/bin/env bats
# Clusterless structural tests for KEDA (event-driven autoscaling, ADR-0029).
# Validates GitOps wiring (Application shape, namespace PSA labels, NetworkPolicy
# overlay), the Alloy metrics scrape job, and the Grafana dashboard — no running
# cluster required. New CHARTER Goal ("event-driven autoscaling") — first item.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "keda Application exists" {
  [ -f "$REPO/gitops/platform/keda.yaml" ]
}

@test "keda Application sources the chart from kedacore.github.io/charts" {
  run grep -q 'repoURL: https://kedacore.github.io/charts' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application pins chart version 2.18.0" {
  run grep -q 'targetRevision: 2.18.0' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application targets the keda namespace" {
  run grep -q 'namespace: keda' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application installs CRDs via the chart (crds.install: true)" {
  [ "$(yqs '.spec.source.helm.valuesObject.crds.install' "$REPO/gitops/platform/keda.yaml")" = "true" ]
}

@test "keda Application sets memory limits per ADR-0029 footprint controls" {
  run grep -q 'memory: 128Mi' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'memory: 64Mi' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application syncs with ServerSideApply (its scaledjobs CRD exceeds the client-side-apply cap)" {
  # scaledjobs.keda.sh is ~634 KB — over the 262144-byte client-side-apply
  # annotation limit — same failure class ADR-0019 hit for Kyverno.
  [ "$(yqs '.spec.syncPolicy.syncOptions | contains(["ServerSideApply=true"])' "$REPO/gitops/platform/keda.yaml")" = "true" ]
}

# --- keda-extras (namespace pre-creation, wave 0) ------------------------------
@test "keda-extras Application exists" {
  [ -f "$REPO/gitops/platform/keda-extras.yaml" ]
}

@test "keda-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/keda-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (restricted — no carve-out needed, ADR-0029) --------
@test "keda namespace manifest exists" {
  [ -f "$REPO/gitops/keda/namespace.yaml" ]
}

@test "keda namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "keda namespace has enforce-version: latest" {
  run grep -q 'enforce-version: latest' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "keda namespace has warn and audit at restricted too" {
  run grep -q 'warn: restricted' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'audit: restricted' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 fan-out, wave 4) --------------------------
@test "keda networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/keda/networkpolicy/kustomization.yaml" ]
}

@test "keda networkpolicy overlay references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/keda/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "keda networkpolicy overlay references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/keda/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "keda allow-webhook-from-apiserver rule permits TCP 9443" {
  run grep -q 'port: "9443"' "$REPO/gitops/keda/networkpolicy/allow-keda-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "keda allow-metrics-from-observability rule permits TCP 8080" {
  run grep -q 'port: 8080' "$REPO/gitops/keda/networkpolicy/allow-keda-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "keda allow-metrics rule selects Alloy pods from observability namespace" {
  run grep -q 'name: alloy' "$REPO/gitops/keda/networkpolicy/allow-keda-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'observability' "$REPO/gitops/keda/networkpolicy/allow-keda-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "keda-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/keda-networkpolicy.yaml" ]
}

@test "keda-networkpolicy Application runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "keda-networkpolicy uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Observability: Alloy scrape + Grafana dashboard --------------------------
@test "observability-alloy has a keda scrape job" {
  run grep -q 'prometheus.scrape "keda"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "keda scrape targets the operator Service on port 8080" {
  run grep -q 'keda-operator.keda.svc.cluster.local:8080' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-keda.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-keda.json" ]
}

@test "lab-keda.json is valid JSON" {
  run python3 -c "import json; json.load(open('$REPO/grafana/dashboards/lab-keda.json'))"
  [ "$status" -eq 0 ]
}

@test "lab-keda.json uid is lab-keda" {
  [ "$(yqs '.uid' "$REPO/grafana/dashboards/lab-keda.json")" = "lab-keda" ]
}

@test "lab-keda.json uses the Mimir datasource (ADR-0004 — real data only)" {
  run grep -q '"uid": "mimir"' "$REPO/grafana/dashboards/lab-keda.json"
  [ "$status" -eq 0 ]
}

@test "lab-keda.json charts keda_scaler_active" {
  run grep -q 'keda_scaler_active' "$REPO/grafana/dashboards/lab-keda.json"
  [ "$status" -eq 0 ]
}

@test "lab-keda.json charts keda_scaled_object_paused" {
  run grep -q 'keda_scaled_object_paused' "$REPO/grafana/dashboards/lab-keda.json"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md documents the keda component" {
  run grep -q 'keda' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

# --- ADR-0017 amendment --------------------------------------------------------
@test "ADR-0017 has a keda: restricted row" {
  run grep -q '`keda` | `restricted`' "$REPO/docs/decisions/adr-0017-pod-security-standards-restricted.md"
  [ "$status" -eq 0 ]
}

# --- Additive-only: no ScaledObject wired to any existing workload yet --------
@test "no ScaledObject or ScaledJob CR exists yet outside gitops/keda/ (engine-only, ADR-0029 scope)" {
  run grep -rl 'kind: ScaledObject\|kind: ScaledJob' "$REPO/gitops"
  # Either nothing found (status 1, grep convention) or every hit lives under gitops/keda/.
  if [ "$status" -eq 0 ]; then
    while IFS= read -r f; do
      case "$f" in
        "$REPO/gitops/keda/"*) ;;
        *) echo "unexpected ScaledObject/ScaledJob outside gitops/keda/: $f"; return 1 ;;
      esac
    done <<< "$output"
  fi
}
