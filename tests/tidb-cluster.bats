#!/usr/bin/env bats
# Clusterless structural tests for the TiDB database version pin
# (gitops/tidb/tidb-cluster.yaml). TiDB itself is on-demand (`make tidb-up`);
# no ADR governs its database version specifically (only tidb-operator's own
# chart pin is separately tracked), so this is a plain currency recurrence
# guard mirroring this repo's other per-component image/version pin
# assertions (e.g. tests/argo-rollouts.bats).
#
# Also covers grafana/dashboards/tidb-demo.json, which had zero bats coverage
# anywhere in the repo (existed since PR #34, mirrors the coverage every other
# on-demand component's dashboard already has — e.g. tests/harbor.bats,
# tests/longhorn.bats, tests/istio-observability.bats — but was missed).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TIDB_CLUSTER="$REPO/gitops/tidb/tidb-cluster.yaml"
  TIDB_DEMO_DASHBOARD="$REPO/grafana/dashboards/tidb-demo.json"
}

@test "tidb-cluster.yaml exists" {
  [ -f "$TIDB_CLUSTER" ]
}

@test "TidbCluster pins a specific 8.x version (not latest/main)" {
  run grep -qE 'version: "v8\.' "$TIDB_CLUSTER"
  [ "$status" -eq 0 ]
}

@test "TidbCluster version pin is at least v8.5.7 (2026-07-23 currency bump)" {
  run grep -q 'version: "v8.5.7"' "$TIDB_CLUSTER"
  [ "$status" -eq 0 ]
}

# --- tidb-demo.json dashboard (learning-path step 4) --------------------------

@test "tidb-demo.json dashboard exists" {
  [ -f "$TIDB_DEMO_DASHBOARD" ]
}

@test "tidb-demo.json is valid JSON" {
  run jq empty "$TIDB_DEMO_DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "tidb-demo.json has uid lab-tidb-demo" {
  run grep -q '"uid": "lab-tidb-demo"' "$TIDB_DEMO_DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "tidb-demo.json has a real Mimir datasource panel referencing the tidb namespace (ADR-0004)" {
  run grep -q 'namespace=\\"tidb\\"' "$TIDB_DEMO_DASHBOARD"
  [ "$status" -eq 0 ]
  run grep -q '"uid": "mimir"' "$TIDB_DEMO_DASHBOARD"
  [ "$status" -eq 0 ]
}

@test "tidb-demo.json contains no fabricated or placeholder data (ADR-0004)" {
  run grep -qi 'placeholder\|TODO\|FIXME\|fake\|dummy\|fabricat' "$TIDB_DEMO_DASHBOARD"
  [ "$status" -ne 0 ]
}
