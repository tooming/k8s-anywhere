#!/usr/bin/env bats
# Clusterless structural tests for the Pyroscope chart pin
# (gitops/platform/observability-pyroscope.yaml). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  APP="$REPO/gitops/platform/observability-pyroscope.yaml"
  DASHBOARD="$REPO/grafana/dashboards/lab-pyroscope.json"
}

@test "pyroscope Application pins chart targetRevision 2.2.1" {
  run grep -q 'targetRevision: 2.2.1' "$APP"
  [ "$status" -eq 0 ]
}

@test "pyroscope Application does not pin the stale 2.2.0 chart" {
  run grep -q 'targetRevision: 2.2.0' "$APP"
  [ "$status" -ne 0 ]
}

# Found live 2026-08-19 (cluster-load reduction sweep): readOnlyRootFilesystem:
# true (ADR-0017) plus the compactor-worker module's own scratch-dir write to
# /tmp (uncovered by either PVC mount) crashed the pod on every single boot --
# 1132 restarts over 8+ days before this was ever caught. Pin the emptyDir fix
# so it can't silently regress.
@test "pyroscope mounts a writable emptyDir at /tmp (compactor-worker needs scratch space; readOnlyRootFilesystem + no /tmp volume crashed every boot for 8+ days, 1132 restarts)" {
  run grep -q 'mountPath: /tmp' "$APP"
  [ "$status" -eq 0 ]
  run grep -A2 'extraVolumes:' "$APP"
  [[ "$output" == *"emptyDir: {}"* ]]
}

# ROADMAP "Loki / Tempo / Pyroscope operational-health dashboards — O5 gap":
# real metric name verified directly against grafana/pyroscope's own Go source.
@test "lab-pyroscope.json exists and is valid JSON" {
  [ -f "$DASHBOARD" ]
  run python3 -c "import json; json.load(open('$DASHBOARD'))"
  [ "$status" -eq 0 ]
}

@test "lab-pyroscope.json references pyroscope_distributor_profiles_received_total (real counter)" {
  run grep -q 'pyroscope_distributor_profiles_received_total' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-pyroscope.json references up{job=\"pyroscope\"} for a component-up panel" {
  run grep -q 'up{job=\\"pyroscope\\"}' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-pyroscope.json uses the mimir datasource on every panel, no fabricated data" {
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
