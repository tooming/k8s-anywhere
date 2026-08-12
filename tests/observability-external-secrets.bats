#!/usr/bin/env bats
# Clusterless structural tests for the lab-external-secrets.json dashboard.
# Per-scope file per tests/observability.bats's frozen-monolith rule — new
# component assertions never get appended there.
#
# Regression guard for a real metric-name-drift bug (same class as PR
# #1155/#1156): externalsecret_sync_calls_total has NO "status" label at all
# (verified against external-secrets v2.9.0 source,
# pkg/controllers/externalsecret/esmetrics/esmetrics.go) — sync attempts and
# sync errors are two SEPARATE counters (externalsecret_sync_calls_total,
# externalsecret_sync_calls_error), not one counter split by a "status"
# label. And externalsecret_sync_calls_duration_seconds_bucket does not
# exist at all — the real duration metric is externalsecret_reconcile_duration,
# a Gauge (last-observed value in nanoseconds), not a Histogram, so no
# "_bucket" series and no histogram_quantile() is possible against it.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DASH="$REPO/grafana/dashboards/lab-external-secrets.json"
}

@test "lab-external-secrets.json dashboard exists" {
  [ -f "$DASH" ]
}

@test "lab-external-secrets.json Sync Errors panel uses the real externalsecret_sync_calls_error counter" {
  run grep -q 'externalsecret_sync_calls_error' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-external-secrets.json does not filter externalsecret_sync_calls_total by a nonexistent status label" {
  run grep -q 'externalsecret_sync_calls_total{status=' "$DASH"
  [ "$status" -eq 1 ]
}

@test "lab-external-secrets.json does not query the nonexistent externalsecret_sync_calls_duration_seconds_bucket metric" {
  run grep -q 'externalsecret_sync_calls_duration_seconds_bucket' "$DASH"
  [ "$status" -eq 1 ]
}

@test "lab-external-secrets.json reconcile-duration panel uses the real externalsecret_reconcile_duration gauge" {
  run grep -q 'externalsecret_reconcile_duration' "$DASH"
  [ "$status" -eq 0 ]
}
