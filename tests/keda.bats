#!/usr/bin/env bats
# Clusterless structural tests for KEDA (event-driven autoscaling, ADR-0029).
# Validates GitOps wiring (Application shape, namespace PSA labels, NetworkPolicy
# overlay) — no running cluster required. New CHARTER Goal ("event-driven
# autoscaling") — first item. The Alloy metrics scrape job and Grafana
# dashboard this file used to also test were removed 2026-09-06 (ADR-0041,
# observability stack removed with no replacement).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
}

# --- ArgoCD Application shape (on-demand, manual sync) -------------------------
@test "keda Application exists" {
  [ -f "$REPO/gitops/platform/keda.yaml" ]
}

@test "keda Application sources the chart from kedacore.github.io/charts" {
  run grep -q 'repoURL: https://kedacore.github.io/charts' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application pins chart version 2.20.2" {
  run grep -q 'targetRevision: 2.20.2' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

# Converted always-on -> on-demand 2026-08-25 (ADR-0029's Re-evaluation log,
# cluster-load reduction): KEDA is reactive/event-driven by design, nothing in
# this lab generates sustained scaling-signal load outside an active demo.
@test "keda Application is manual sync only (on-demand, not auto-synced)" {
  run grep -q 'automated:' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 1 ]
}

@test "keda-extras Application is also manual sync only (on-demand)" {
  run grep -q 'automated:' "$REPO/gitops/platform/keda-extras.yaml"
  [ "$status" -eq 1 ]
}

@test "Makefile has keda-up and keda-down on-demand targets" {
  grep -q '^keda-up:' "$REPO/Makefile"
  grep -q '^keda-down:' "$REPO/Makefile"
}

@test "keda Application targets the keda namespace" {
  run grep -q 'namespace: keda' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

@test "keda Application installs CRDs via the chart (crds.install: true)" {
  [ "$(yqs '.spec.source.helm.valuesObject.crds.install' "$REPO/gitops/platform/keda.yaml")" = "true" ]
}

@test "keda Application runs at sync-wave 6 (after cert-manager-root-ca issues k8s-lab-ca)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$REPO/gitops/platform/keda.yaml"
  [ "$status" -eq 0 ]
}

# --- Admission webhook TLS via cert-manager (ADR-0029 §"Scope & exceptions" follow-up) --
@test "keda Application enables cert-manager for webhook TLS" {
  [ "$(yqs '.spec.source.helm.valuesObject.certificates.certManager.enabled' "$REPO/gitops/platform/keda.yaml")" = "true" ]
}

@test "keda Application references the k8s-lab-ca ClusterIssuer (not the chart's generated one)" {
  [ "$(yqs '.spec.source.helm.valuesObject.certificates.certManager.issuer.generate' "$REPO/gitops/platform/keda.yaml")" = "false" ]
  [ "$(yqs '.spec.source.helm.valuesObject.certificates.certManager.issuer.name' "$REPO/gitops/platform/keda.yaml")" = "k8s-lab-ca" ]
  [ "$(yqs '.spec.source.helm.valuesObject.certificates.certManager.issuer.kind' "$REPO/gitops/platform/keda.yaml")" = "ClusterIssuer" ]
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

# --- keda-extras (namespace pre-creation, wave 6) ------------------------------
# "keda-extras Application exists" lives in tests/securitycontext-keda.bats
# (removed here 2026-08-27 — exact duplicate, same target file, found in a
# cross-file duplication sweep).
@test "keda-extras runs at sync-wave 6 (moved alongside keda, ADR-0029 webhook-TLS follow-up)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$REPO/gitops/platform/keda-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (restricted — no carve-out needed, ADR-0029) --------
# "keda namespace enforces PSS restricted" and "...has enforce-version: latest"
# live in tests/securitycontext-keda.bats (removed here 2026-08-27 — exact
# duplicates, same target file).
@test "keda namespace manifest exists" {
  [ -f "$REPO/gitops/keda/namespace.yaml" ]
}

@test "keda namespace has warn and audit at restricted too" {
  run grep -q 'warn: restricted' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'audit: restricted' "$REPO/gitops/keda/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 fan-out, wave 6) --------------------------
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

@test "keda allow-metrics-from-observability rule no longer exists (ADR-0041)" {
  [ ! -f "$REPO/gitops/keda/networkpolicy/allow-keda-metrics-from-observability.yaml" ]
}

@test "keda-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/keda-networkpolicy.yaml" ]
}

@test "keda-networkpolicy Application runs at sync-wave 6 (moved alongside keda, ADR-0029 webhook-TLS follow-up)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "keda-networkpolicy uses LoadRestrictionsNone" {
  run grep -q 'LoadRestrictionsNone' "$REPO/gitops/platform/keda-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

# --- Observability: Alloy scrape + Grafana dashboard REMOVED 2026-09-06
# (ADR-0041, observability stack removed with no replacement) --------------------
@test "grafana/dashboards/lab-keda.json no longer exists (ADR-0041)" {
  [ ! -f "$REPO/grafana/dashboards/lab-keda.json" ]
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
@test "the only ScaledObject/ScaledJob CRs are the rabbitmq-load-scaler demo (ADR-0029 ScaledObject-demo follow-up)" {
  run grep -rl 'kind: ScaledObject\|kind: ScaledJob' "$REPO/gitops"
  [ "$status" -eq 0 ]
  while IFS= read -r f; do
    case "$f" in
      "$REPO/gitops/data/demo/keda-scaling/scaledobject.yaml") ;;
      *) echo "unexpected ScaledObject/ScaledJob outside the rabbitmq-load-scaler demo: $f"; return 1 ;;
    esac
  done <<< "$output"
}
