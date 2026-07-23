#!/usr/bin/env bats
# Clusterless structural checks for the Envoy Gateway control plane wiring
# (ADR-0008). Asserts the Application exists, is auto-synced (always-on,
# unlike the on-demand heavy components in platform.bats), and pins the
# chart version ADR-0008's Re-evaluation log records as current — a
# recurrence guard mirroring the existing Cilium/Argo Rollouts/Kiali
# chart-pin assertions.

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

@test "envoy-gateway Application sources the gateway-helm chart from docker.io/envoyproxy" {
  run grep -q 'repoURL: docker.io/envoyproxy' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -eq 0 ]
}

# --- Chart pin (ADR-0008 Re-evaluation log, 2026-07-23 audit, RFC #671) -----
@test "envoy-gateway Application pins chart version v1.8.3 (TLS secret validation fix)" {
  run grep -q 'targetRevision: v1.8.3' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -eq 0 ]
}

@test "envoy-gateway Application does not pin the superseded v1.8.2 version" {
  run grep -q 'targetRevision: v1.8.2' "$REPO/gitops/platform/envoy-gateway.yaml"
  [ "$status" -ne 0 ]
}
