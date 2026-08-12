#!/usr/bin/env bats
# Clusterless structural tests for KSM self-monitoring wiring.
# Per-scope file per tests/observability.bats's frozen-monolith rule — new
# component assertions never get appended there.
#
# Regression guard: lab-ksm.json's "KSM Version" (kube_state_metrics_build_info)
# and "KSM Watch Total by Resource" (kube_state_metrics_watch_total) panels were
# structurally guaranteed to never show data — those metrics are exposed only on
# KSM's separate :8081 telemetry port (chart default `selfMonitor.enabled: false`
# never opens a Service port for it), while Alloy's only KSM scrape target hit
# :8080 (the main kube_* cluster-object metrics port). Verified against the
# kube-state-metrics chart 8.2.0 source (templates/service.yaml, templates/
# deployment.yaml) — same class of bug as PR #1155/#1156's dashboard
# metric-name-drift fixes, this time a missing scrape target rather than a wrong
# metric name.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  KSM_APP="$REPO/gitops/platform/observability-ksm.yaml"
  ALLOY_APP="$REPO/gitops/platform/observability-alloy.yaml"
}

@test "observability-ksm.yaml enables selfMonitor (opens the :8081 telemetry Service port)" {
  run grep -q 'selfMonitor:' "$KSM_APP"
  [ "$status" -eq 0 ]
  run grep -A1 'selfMonitor:' "$KSM_APP"
  [[ "$output" == *"enabled: true"* ]]
}

@test "observability-ksm.yaml does not enable kubeRBACProxy (would wrap :8081 in HTTPS+RBAC)" {
  run grep -q 'kubeRBACProxy:' "$KSM_APP"
  [ "$status" -eq 1 ]
}

@test "observability-alloy.yaml scrapes KSM's self-monitoring telemetry port :8081" {
  run grep -q 'prometheus.scrape "ksm_self"' "$ALLOY_APP"
  [ "$status" -eq 0 ]
  run grep -q 'kube-state-metrics.observability.svc.cluster.local:8081' "$ALLOY_APP"
  [ "$status" -eq 0 ]
}
