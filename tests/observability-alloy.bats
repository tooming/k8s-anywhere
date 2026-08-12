#!/usr/bin/env bats
# lab-alloy.json dashboard metric-drift fix (2026-08-12, 5th audit batch).
# "Remote write bytes /s (to Mimir)" queried prometheus_remote_storage_sent_bytes_total,
# which does not exist anywhere in prometheus/prometheus (verified against the exact
# vendored version Alloy v1.18.0 ships, v0.312.0 -- storage/remote/queue_manager.go +
# storage/remote/storage.go). The real metric is Namespace=prometheus/
# Subsystem=remote_storage/Name=bytes_total, i.e. prometheus_remote_storage_bytes_total.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DASH="$REPO/grafana/dashboards/lab-alloy.json"
}

@test "lab-alloy.json references the real prometheus_remote_storage_bytes_total metric" {
  run grep -q 'prometheus_remote_storage_bytes_total' "$DASH"
  [ "$status" -eq 0 ]
}

@test "lab-alloy.json does not reference the fabricated sent_bytes_total metric name" {
  run grep -q 'prometheus_remote_storage_sent_bytes_total' "$DASH"
  [ "$status" -eq 1 ]
}
