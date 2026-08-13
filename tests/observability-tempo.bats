#!/usr/bin/env bats
# Clusterless structural tests for the Tempo image tag pin
# (gitops/observability/tempo/deployment.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DEPLOYMENT="$REPO/gitops/observability/tempo/deployment.yaml"
  DASHBOARD="$REPO/grafana/dashboards/lab-tempo.json"
}

@test "tempo deployment pins image tag 2.10.8" {
  run grep -q 'image: grafana/tempo:2.10.8' "$DEPLOYMENT"
  [ "$status" -eq 0 ]
}

@test "tempo deployment does not pin the superseded 2.10.7 tag" {
  run grep -q 'image: grafana/tempo:2.10.7' "$DEPLOYMENT"
  [ "$status" -eq 1 ]
}

# ROADMAP "Loki / Tempo / Pyroscope operational-health dashboards — O5 gap":
# real metric names verified directly against grafana/tempo's own Go source.
@test "lab-tempo.json exists and is valid JSON" {
  [ -f "$DASHBOARD" ]
  run python3 -c "import json; json.load(open('$DASHBOARD'))"
  [ "$status" -eq 0 ]
}

@test "lab-tempo.json references tempo_distributor_spans_received_total (real counter)" {
  run grep -q 'tempo_distributor_spans_received_total' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-tempo.json references tempo_distributor_bytes_received_total (real counter)" {
  run grep -q 'tempo_distributor_bytes_received_total' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-tempo.json references up{job=\"tempo\"} for a component-up panel" {
  run grep -q 'up{job=\\"tempo\\"}' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-tempo.json uses the mimir datasource on every panel, no fabricated data" {
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
