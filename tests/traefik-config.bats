#!/usr/bin/env bats
# Clusterless structural checks for the Traefik probe/resource tuning
# (gitops/platform/traefik-config.yaml, gitops/traefik-config/). See that
# Application's own header comment for the live 2026-09-06 finding this fixes:
# Traefik's stock chart probes (timeoutSeconds: 2, readiness failureThreshold: 1)
# are too tight for this lab's real host contention, causing a liveness-probe
# restart loop that left the front door answering every request with a bare
# 404 even for error-free, Host()-matched IngressRoutes.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/traefik-config.yaml"
  CFG="$REPO/gitops/traefik-config/helmchartconfig.yaml"
}

@test "traefik-config Application file exists" {
  [ -f "$APP" ]
}

@test "traefik-config Application targets kube-system namespace" {
  run grep 'namespace: kube-system' "$APP"
  [ "$status" -eq 0 ]
}

@test "traefik-config Application is auto-synced (no bootstrap-order constraint, unlike Cilium)" {
  run grep -E '^[[:space:]]*automated:' "$APP"
  [ "$status" -eq 0 ]
}

@test "traefik-config HelmChartConfig manifest exists" {
  [ -f "$CFG" ]
}

@test "HelmChartConfig name and namespace match the k3s-managed HelmChart/traefik exactly" {
  run grep -q '^  name: traefik$' "$CFG"
  [ "$status" -eq 0 ]
  run grep -q '^  namespace: kube-system$' "$CFG"
  [ "$status" -eq 0 ]
}

@test "HelmChartConfig widens readinessProbe and livenessProbe timeouts past the chart's stock 2s" {
  run grep -q 'timeoutSeconds: 10' "$CFG"
  [ "$status" -eq 0 ]
}

@test "HelmChartConfig raises readiness failureThreshold past the chart's stock 1 (a single slow response must not flip Traefik NotReady)" {
  run grep -A2 'readinessProbe:' "$CFG"
  [[ "$output" == *"failureThreshold: 3"* ]]
}

@test "HelmChartConfig sets explicit resource requests (the chart ships none by default)" {
  run grep -A3 'resources:' "$CFG"
  [[ "$output" == *"requests:"* ]]
  [[ "$output" == *"cpu: 50m"* ]]
}

@test "gitops/traefik-config kustomization references the HelmChartConfig (no orphan)" {
  run grep -q 'helmchartconfig.yaml' "$REPO/gitops/traefik-config/kustomization.yaml"
  [ "$status" -eq 0 ]
}
