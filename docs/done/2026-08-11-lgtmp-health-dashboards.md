# Loki / Tempo / Pyroscope operational-health dashboards — O5 gap

(CHARTER **Objective O5** "every Application in `gitops/bootstrap/root-app.yaml`'s
auto-synced set has a matching `grafana/dashboards/lab-<name>.json` with at least
one panel backed by a real (auto-discovered) data source"; planner gap analysis
2026-08-11, reached via `executor.prompt.md` STEP 6b PLANNER role, this session's
6th cycle, after cycles 4 and 5 each independently confirmed the standing Now/next
lane and CHARTER Objective O2 both fully exhausted/met, per STEP 8's "widen the
lens" guidance. **No prerequisites — executor may pick up immediately.**) Verified
directly (not assumed, ADR-0004): `gitops/platform/observability-alloy.yaml`'s
`prometheus.scrape "lgtmp"` block already scraped
`loki.observability.svc.cluster.local:3100`, `tempo.observability.svc.cluster.
local:3200`, and `pyroscope.observability.svc.cluster.local:4040` with
`job="loki"`/`job="tempo"`/`job="pyroscope"` labels (the same block that already
fed `lab-mimir.json` and `lab-grafana.json` for their sibling components) — but
grepping every `grafana/dashboards/*.json` file for any `loki_`/`tempo_`/
`pyroscope_`-prefixed Prometheus expression found zero hits anywhere.
`lab-logs.json`/`lab-traces.json`/`lab-profiles.json` existed, but they're
data-browsing dashboards (a log-search panel, a TraceQL search + trace view, a
profile flamegraph) — none had a single pod-running/ArgoCD-sync/component-health
panel, unlike every sibling LGTMP-stack dashboard.

Real metric names verified directly against each project's own Go source
(shallow-cloned `grafana/loki`, `grafana/tempo`, `grafana/pyroscope` and grepped
each `promauto`/`prometheus.New*` metric declaration's `Namespace` + `Name`
fields — not assumed from memory or community dashboards):
- **Loki** (`pkg/ingester/metrics.go`, `pkg/distributor/distributor.go`):
  `loki_ingester_memory_chunks` (gauge, total chunks held in memory) and
  `loki_distributor_ingester_appends_total` (counter, ingester append calls).
- **Tempo** (`modules/distributor/distributor.go`):
  `tempo_distributor_spans_received_total` (counter, labeled `tenant`) and
  `tempo_distributor_bytes_received_total` (counter, labeled `tenant`).
- **Pyroscope** (`pkg/distributor/metrics.go`):
  `pyroscope_distributor_profiles_received_total` (counter, labeled
  `tenant`/`scope_name`/`scope_version`).
- All three: the standard Prometheus self-instrumentation gauge
  `up{job="loki"}` / `up{job="tempo"}` / `up{job="pyroscope"}` for a "component
  up" stat panel — mirrors `lab-mimir.json`'s own "Mimir up" panel exactly.

Added three new dashboard files mirroring `lab-mimir.json`'s exact panel shape
(stat row: up / a gauge or counter-rate metric / a second throughput metric;
a timeseries row for the throughput metrics over time): `grafana/dashboards/
lab-loki.json` ("Lab — Loki"), `grafana/dashboards/lab-tempo.json` ("Lab — Tempo"),
`grafana/dashboards/lab-pyroscope.json` ("Lab — Pyroscope"). These are additive,
distinct from the existing `lab-logs.json`/`lab-traces.json`/`lab-profiles.json`
data-browsing dashboards — those were left untouched, they serve a different
purpose. All panels use the real `mimir` datasource with real metric expressions.

Extended the existing per-component bats files (`tests/observability-loki.bats`,
`tests/observability-tempo.bats`, `tests/observability-pyroscope.bats` — which
already existed, covering only each component's image/chart version pin) rather
than creating new `tests/observability-<scope>.bats` files: each new dashboard is
valid JSON, references its real metric name(s), uses the `mimir` datasource on
every panel, and carries no fabricated/placeholder data. Updated
`docs/dependency-tree.md` with three new Grafana-dashboard rows noting the real
metric sourcing and that the scrape infrastructure was already in place (no new
scrape job needed).

## ADR-0004 caveat

This remote clusterless session cannot confirm live which of the six new metrics
actually emit a series without a real scrape target — any that don't will show
"No data" naturally in Grafana, never a fabricated value.

## Rollback path

Delete the three new dashboard files (`lab-loki.json`, `lab-tempo.json`,
`lab-pyroscope.json`). Grafana's native Git Sync (ADR-0006) picks up the removal
on its next sync — no other component is affected, since nothing else reads these
files.

## PR

https://github.com/tooming/k8s-anywhere/pull/1131
