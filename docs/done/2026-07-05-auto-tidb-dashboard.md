# Lab — TiDB on-demand Alloy scrape + dashboard

**Lab — TiDB on-demand Alloy scrape + dashboard** (CHARTER **Core Values**
§"Real observability only"; O5 gap-fill for on-demand components — follows the
`lab-kargo.json` / `lab-inkless.json` precedent; **no prerequisites — executor
may pick up immediately**). The TiDB namespace NetworkPolicy already permits
ingress TCP 10080 from `observability`
(`gitops/tidb/networkpolicy/allow-tidb-from-observability.yaml`) but the
corresponding Alloy scrape job and dashboard were never added; the NP comment
references a scrape job that does not yet exist. Added `prometheus.scrape "tidb"`
block to `gitops/platform/observability-alloy.yaml` (static target
`lab-tidb.tidb.svc.cluster.local:10080`; `scrape_interval = "30s"`; inline
comment explaining this target is idle unless `make tidb-up` is active — mirrors
the `kargo` scrape block comment). The TiDB Operator creates a service named
`<cluster>-tidb` for the cluster CR; since the lab TidbCluster is named `lab`,
the service is `lab-tidb`. New `grafana/dashboards/lab-tidb.json` ("Lab — TiDB
(Distributed Database)") with stat-row: TiDB server ready
(`kube_statefulset_status_replicas_ready{namespace="tidb"}`); TiDB operator
running (`kube_deployment_status_replicas_available{namespace="tidb-admin"}`);
cluster memory; ArgoCD sync state. Plus two timeseries panels: query execution
rate (`tidb_executor_statement_total` by type) and active connections
(`tidb_server_connections`), plus a server memory timeseries
(`container_memory_working_set_bytes{namespace="tidb",container=~"tidb.*"}`). All
panels use real Mimir data with `X-Scope-OrgID: lab`; panels show "No data"
naturally when TiDB is not running (ADR-0004, on-demand). Extended
`tests/observability.bats` with four assertions: scrape block `"tidb"` present in
`observability-alloy.yaml`; `lab-tidb.json` exists; dashboard references `tidb`
namespace; no fabricated/placeholder data. Updated `docs/dependency-tree.md` with
TiDB observability note.

## PR

PR #332 — https://github.com/tooming/k8s-lab/pull/332
