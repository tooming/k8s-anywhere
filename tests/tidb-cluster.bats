#!/usr/bin/env bats
# Clusterless structural tests for the TiDB database version pin
# (gitops/tidb/tidb-cluster.yaml). TiDB itself is on-demand (`make tidb-up`);
# no ADR governs its database version specifically (only tidb-operator's own
# chart pin is separately tracked), so this is a plain currency recurrence
# guard mirroring this repo's other per-component image/version pin
# assertions (e.g. tests/argo-rollouts.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TIDB_CLUSTER="$REPO/gitops/tidb/tidb-cluster.yaml"
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
