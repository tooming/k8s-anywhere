#!/usr/bin/env bats
# Clusterless structural checks for the Envoy Gateway control plane wiring
# (ADR-0008). Asserts the Application exists, is auto-synced (always-on,
# unlike the on-demand heavy components in platform.bats), and pins the
# chart version ADR-0008's Re-evaluation log records as current — a
# recurrence guard mirroring the existing Cilium/Argo Rollouts/Kiali
# chart-pin assertions.
#
# Sourced via a local Kustomize overlay (gitops/envoy-gateway/) since
# 2026-08-25, not ArgoCD's native Helm source — see that file's own comment
# and gitops/platform/envoy-gateway.yaml's header for why (a probe timeout
# the chart hardcodes with no values.yaml override hook).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "envoy-gateway Application file exists" {
  [ -f "$REPO/gitops/platform/envoy-gateway.yaml" ]
}

@test "envoy-gateway Application is auto-synced (always-on control plane)" {
  run grep -E '^[[:space:]]*automated:' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway Application sources gitops/envoy-gateway via the local Forgejo repo (Kustomize overlay, not ArgoCD's native Helm source)" {
  run grep -q 'path: gitops/envoy-gateway' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway Application does not use spec.source.kustomize.buildOptions (dead field on this cluster's Application CRD -- see infra/modules/argocd/values.yaml for the working global equivalent)" {
  run grep -q '^\s*buildOptions:' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -ne 0 ]
}

@test "gitops/envoy-gateway/kustomization.yaml exists" {
  [ -f "$REPO/gitops/envoy-gateway/kustomization.yaml" ]
}

@test "gitops/envoy-gateway/kustomization.yaml vendors gateway-helm from docker.io/envoyproxy via the helmCharts inflator" {
  run grep -q 'repo: oci://docker.io/envoyproxy' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'name: gateway-helm' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "infra/modules/argocd/values.yaml enables --enable-helm globally (required for the helmCharts inflator, per-Application buildOptions doesn't work)" {
  run grep -q -- '--enable-helm' "$REPO/infra/modules/argocd/values.yaml"
  [ "$status" -eq 0 ]
}

# --- Chart pin (ADR-0008 Re-evaluation log, 2026-07-23 audit, RFC #671) -----
@test "gitops/envoy-gateway/kustomization.yaml pins chart version v1.8.3 (TLS secret validation fix)" {
  run grep -q 'version: v1.8.3' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "gitops/envoy-gateway/kustomization.yaml does not pin the superseded v1.8.2 version" {
  run grep -q 'version: v1.8.2' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -ne 0 ]
}

# --- Leader election disabled (chronic-bug fix, single-replica ADR-0008/ADR-0005) ---
# controller-runtime's manager enables leader election by default even at
# replicas: 1, where it serves no purpose (one candidate, nothing to
# arbitrate) but still self-inflicts a full-manager restart on any apiserver
# latency spike ("leader election lost") — observed repeatedly, most recently
# 17+ restarts in ~2h during the #631/#633 investigation on 2026-08-07, and it
# takes down every HTTPRoute behind the gateway, not just one. Disabling it
# removes the failure mode by construction rather than widening a timeout
# around it.
@test "gitops/envoy-gateway/kustomization.yaml disables leader election (single replica, chronic 502 fix)" {
  run grep -A2 'leaderElection:' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disable: true"* ]]
}

@test "gitops/envoy-gateway/kustomization.yaml's leaderElection.disable sits under provider.kubernetes (EnvoyGateway config shape)" {
  run grep -B2 'leaderElection:' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubernetes:"* ]]
}

# --- Probe timeout fix (found live 2026-08-25 investigating #633) ----------
# The chart hardcodes livenessProbe/readinessProbe timeoutSeconds: 1 with no
# values.yaml override hook -- same "chart default too tight for this host"
# footgun already fixed via probe timeout bumps across Harbor, ArgoCD's
# repo-server/server, Kyverno, cert-manager, and KEDA. Restart count kept
# climbing after the leaderElection fix alone (153 restarts/13d, all clean
# exitCode 0 "Completed" -- a liveness-probe-kill signature, not a crash).
@test "gitops/envoy-gateway/kustomization.yaml patches the envoy-gateway Deployment's livenessProbe timeoutSeconds to 15" {
  run grep -A2 'livenessProbe/timeoutSeconds' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"value: 15"* ]]
}

@test "gitops/envoy-gateway/kustomization.yaml patches the envoy-gateway Deployment's readinessProbe timeoutSeconds to 15" {
  run grep -A2 'readinessProbe/timeoutSeconds' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"value: 15"* ]]
}

@test "gitops/envoy-gateway/kustomization.yaml's probe patch targets the envoy-gateway Deployment specifically" {
  run grep -B6 'livenessProbe/timeoutSeconds' "$REPO/gitops/envoy-gateway/kustomization.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kind: Deployment"* ]]
  [[ "$output" == *"name: envoy-gateway"* ]]
}

# --- Kustomize helmCharts cache is gitignored -------------------------------
@test ".gitignore excludes the Kustomize helmCharts inflator's local chart-pull cache" {
  run grep -q 'gitops/\*/charts/' "$REPO/.gitignore"
  [ "$status" -eq 0 ]
}
