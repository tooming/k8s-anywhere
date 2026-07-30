# Add missing bats coverage for the tidb-demo.json dashboard

`grafana/dashboards/tidb-demo.json` (the "Lab — TiDB Demo App" dashboard, learning-path
step 4 — end-to-end Vault → ExternalSecret → Secret → Pod injection demo, real Mimir
queries against `kube_pod_status_phase`/`container_memory_working_set_bytes`/
`container_cpu_usage_seconds_total`) has existed since PR #34 (the original Grafana
Git Sync cutover) but had **zero bats coverage anywhere in the repo** — no existence
check, no `uid` check, no real-datasource check, no ADR-0004 fabricated-content check.
`tests/dashboard-coverage.bats`'s `MIMIR_DASHBOARDS` loop deliberately scopes to
always-on service dashboards only (per its own header comment); `tidb-demo` is an
on-demand component so it was correctly out of that loop's scope — but unlike every
other on-demand component's dashboard (`lab-harbor.json` in `tests/harbor.bats`,
`lab-longhorn.json` in `tests/longhorn.bats`, `lab-istio.json` in
`tests/istio-observability.bats`), it never got its own dedicated coverage anywhere
else either. Found via a repo-wide cross-reference of every `grafana/dashboards/*.json`
file's basename against every `tests/*.bats` file — the only dashboard with zero hits.

## Fix

Added 5 tests to `tests/tidb-cluster.bats` (the existing structural-test file for the
on-demand TiDB component, which already covers `gitops/tidb/tidb-cluster.yaml`'s
version pin — a natural home rather than a new file, since it's the same component):
dashboard file exists; is valid JSON; has `uid: lab-tidb-demo`; has a real Mimir
datasource panel referencing the `tidb` namespace (ADR-0004); contains no
fabricated/placeholder content (ADR-0004), mirroring the exact assertion shape
`tests/harbor.bats` already uses for `lab-harbor.json`.

No dashboard content changed — the file was already real, correctly-wired, and
ADR-0004-compliant; this closes a pure test-coverage gap. No topology change, so no
`docs/dependency-tree.md` update needed (line 419 already documents this dashboard's
existence and purpose accurately).

`make ci` passes: 2340 bats assertions (5 new), 0 failures (verified locally with
`bats` installed via `apt-get`, `jq`, and a fetched `mikefarah/yq` v4.53.3 binary —
none present by default in this remote sandbox).

## PR

https://github.com/tooming/k8s-anywhere/pull/905
