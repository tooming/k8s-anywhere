#!/usr/bin/env bats
# Clusterless structural tests for Vault's internal telemetry scrape
# (ROADMAP "Vault internal telemetry — sys/metrics scrape + dashboard depth",
# docs/dora-audit-readiness.md Q7's gap). Per-scope file per
# tests/observability.bats's frozen-monolith rule — new component assertions
# never get appended there. NetworkPolicy coverage lives in
# tests/networkpolicy-vault.bats (the existing per-namespace convention), not
# duplicated here.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VAULT_APP="$REPO/gitops/platform/vault.yaml"
  ALLOY_APP="$REPO/gitops/platform/observability-alloy.yaml"
  DASHBOARD="$REPO/grafana/dashboards/lab-vault.json"
}

# --- vault.yaml: telemetry stanza + unauthenticated metrics access ----------

@test "vault.yaml sets unauthenticated_metrics_access = true on the tcp listener" {
  run grep -q 'unauthenticated_metrics_access = true' "$VAULT_APP"
  [ "$status" -eq 0 ]
}

@test "vault.yaml has a top-level telemetry stanza with prometheus_retention_time" {
  run grep -q 'prometheus_retention_time = "24h"' "$VAULT_APP"
  [ "$status" -eq 0 ]
  run grep -q 'disable_hostname          = true' "$VAULT_APP"
  [ "$status" -eq 0 ]
}

# --- observability-alloy.yaml: the vault scrape job -------------------------

@test "observability-alloy.yaml defines a vault scrape job" {
  run grep -q 'prometheus.scrape "vault" {' "$ALLOY_APP"
  [ "$status" -eq 0 ]
}

@test "vault scrape job targets vault.vault.svc.cluster.local:8200" {
  run grep -q '"__address__" = "vault.vault.svc.cluster.local:8200"' "$ALLOY_APP"
  [ "$status" -eq 0 ]
}

@test "vault scrape job reads the real /v1/sys/metrics path, not the default /metrics" {
  run grep -q 'metrics_path    = "/v1/sys/metrics"' "$ALLOY_APP"
  [ "$status" -eq 0 ]
}

@test "vault scrape job requests Prometheus-format output via params" {
  run grep -q 'params          = {format = \["prometheus"\]}' "$ALLOY_APP"
  [ "$status" -eq 0 ]
}

@test "vault scrape job forwards to the mimir receiver like every other scrape job" {
  run bash -c "grep -A6 'prometheus.scrape \"vault\" {' '$ALLOY_APP' | grep -q 'forward_to      = \[prometheus.remote_write.mimir.receiver\]'"
  [ "$status" -eq 0 ]
}

# --- lab-vault.json: real Vault-internal metric panels, not fabricated ------

@test "lab-vault.json is valid JSON" {
  run python3 -c "import json; json.load(open('$DASHBOARD'))"
  [ "$status" -eq 0 ]
}

@test "lab-vault.json references vault_core_unsealed (real seal-state metric)" {
  run grep -q 'vault_core_unsealed' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-vault.json references vault_core_active (real active/standby metric)" {
  run grep -q 'vault_core_active' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-vault.json references vault_core_in_flight_requests (real in-flight-request metric)" {
  run grep -q 'vault_core_in_flight_requests' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "lab-vault.json references vault_expire_num_leases (real lease-count metric)" {
  run grep -q 'vault_expire_num_leases' "$DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "the four new Vault telemetry panels use the mimir datasource, not a fabricated one" {
  # Confirms each new metric's target block cites the mimir uid (grep -B for the
  # nearest preceding datasource declaration would be fragile across a one-line
  # panel format; instead assert the datasource uid count grew to cover every
  # panel including the four new ones -- 15 panels total after this item).
  run python3 -c "
import json
d = json.load(open('$DASHBOARD'))
panels = d['panels']
assert len(panels) == 15, f'expected 15 panels, got {len(panels)}'
for p in panels:
    for t in p.get('targets', []):
        assert t['datasource']['uid'] == 'mimir', f'{p[\"title\"]} does not use mimir'
print('ok')
"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "lab-vault.json has no fabricated or placeholder data (ADR-0004)" {
  run grep -iE '"expr": "(1|0|42)"' "$DASHBOARD"
  [ "$status" -eq 1 ]
  run grep -iq 'placeholder\|dummy\|fake\|mock' "$DASHBOARD"
  [ "$status" -eq 1 ]
}
