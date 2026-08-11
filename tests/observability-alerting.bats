#!/usr/bin/env bats
# Clusterless structural tests for Grafana Unified Alerting (RFC #1084).
# Per-scope file per tests/observability.bats's frozen-monolith rule — new
# component assertions never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/observability-grafana.yaml"
}

@test "grafana Application defines the alerting provisioning block" {
  run grep -q '^        alerting:' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: ArgoCDAppUnhealthy rule present with correct expr and for" {
  run grep -q 'title: ArgoCDAppUnhealthy' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'expr: argocd_app_info{health_status!="Healthy"} == 1' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: ArgoCDAppOutOfSync rule present with correct expr and for" {
  run grep -q 'title: ArgoCDAppOutOfSync' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'expr: argocd_app_info{sync_status="OutOfSync"} == 1' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: DeploymentReplicasUnavailable rule present with correct expr" {
  run grep -q 'title: DeploymentReplicasUnavailable' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'expr: kube_deployment_status_replicas_available < kube_deployment_spec_replicas' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: PVCStuckPendingOrLost rule present with correct expr" {
  run grep -q 'title: PVCStuckPendingOrLost' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'expr: kube_persistentvolumeclaim_status_phase{phase=~"Pending|Lost"} == 1' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: VaultPodNotReady rule present with correct expr (ROADMAP auto/vault-pod-readiness-alert)" {
  run grep -q 'title: VaultPodNotReady' "$APP"
  [ "$status" -eq 0 ]
  run grep -q 'expr: kube_pod_status_ready{namespace="vault", pod=~"vault-\[0-9\]+", condition="true"} == 0' "$APP"
  [ "$status" -eq 0 ]
}

@test "grafana alerting: all five rules use the 'for' durations named in RFC #1084 / ROADMAP auto/vault-pod-readiness-alert" {
  # ArgoCDAppUnhealthy, DeploymentReplicasUnavailable, PVCStuckPendingOrLost,
  # VaultPodNotReady: 10m. ArgoCDAppOutOfSync: 30m. Count occurrences rather than
  # assert line adjacency, since bats/grep has no easy YAML-block-scoped assertion
  # here.
  run grep -c 'for: 10m' "$APP"
  [ "$status" -eq 0 ]
  [ "$output" -eq 4 ]
  run grep -c 'for: 30m' "$APP"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "grafana alerting: all five rules query the mimir datasource, not a new one" {
  run grep -c 'datasourceUid: mimir' "$APP"
  [ "$status" -eq 0 ]
  [ "$output" -eq 5 ]
}

@test "grafana alerting: no notification receiver/contact-point config exists (RFC #1084 — visual-only)" {
  run grep -qE 'contactPoints:|notificationPolicies:|^\s*receivers:|smtp|webhook_configs|slack_configs|pagerduty_configs' "$APP"
  [ "$status" -ne 0 ]
}
