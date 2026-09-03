#!/usr/bin/env bats
# Clusterless structural tests for the Loki image tag pin
# (gitops/observability/loki/deployment.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOYMENT="$REPO/gitops/observability/loki/deployment.yaml"
  DASHBOARD="$REPO/grafana/dashboards/lab-loki.json"
}

@test "loki deployment pins image tag 3.7.7" {
  run grep -q 'image: grafana/loki:3.7.7' "$DEPLOYMENT"
  [ "$status" -eq 0 ]
}

@test "loki deployment does not pin the stale 3.7.6 tag" {
  run grep -q 'image: grafana/loki:3.7.6' "$DEPLOYMENT"
  [ "$status" -ne 0 ]
}

# ROADMAP "Loki / Tempo / Pyroscope operational-health dashboards — O5 gap":
# real metric names verified directly against grafana/loki's own Go source.
@test "lab-loki.json exists and is valid JSON" {
  [ -f "$DASHBOARD" ]
  run python3 -c "import json; json.load(open('$DASHBOARD'))"
  [ "$status" -eq 0 ]
}

@test "lab-loki.json references loki_ingester_memory_chunks (real gauge)" {
  run grep -q 'loki_ingester_memory_chunks' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-loki.json references loki_distributor_ingester_appends_total (real counter)" {
  run grep -q 'loki_distributor_ingester_appends_total' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-loki.json references up{job=\"loki\"} for a component-up panel" {
  run grep -q 'up{job=\\"loki\\"}' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-loki.json uses the mimir datasource on every panel, no fabricated data" {
  run python3 -c "
import json
d = json.load(open('$DASHBOARD'))
for p in d['panels']:
    for t in p.get('targets', []):
        assert t['datasource']['uid'] == 'mimir', f'{p[\"title\"]} does not use mimir'
print('ok')
"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
  run grep -iq 'placeholder\|dummy\|fake\|mock' "$DASHBOARD"
  [ "$status" -eq 1 ]
}
