# Lab — Longhorn on-demand Alloy scrape + dashboard

(CHARTER **Core Values** §"Real observability only"; O5 gap-fill for on-demand components —
follows the `lab-kargo.json` / `lab-inkless.json` precedent; **no prerequisites — executor
may pick up immediately**). The Longhorn namespace NetworkPolicy already permits ingress TCP
9500 from `observability` (`gitops/longhorn/networkpolicy/allow-longhorn-metrics-ingress.yaml`)
but no Alloy scrape job or Grafana dashboard had been added yet. Add
`prometheus.scrape "longhorn"` block to `gitops/platform/observability-alloy.yaml` (static
target `longhorn-manager.longhorn-system.svc.cluster.local:9500`; `scrape_interval = "30s"`;
add an inline comment explaining this target is idle unless `make longhorn-up` is active —
mirrors the `kargo` scrape block comment). New `grafana/dashboards/lab-longhorn.json` ("Lab —
Longhorn (Block Storage)") modelled on `lab-kargo.json` stat-row: longhorn-manager DaemonSet
ready (KSM `kube_daemonset_status_number_ready{namespace="longhorn-system",daemonset=~"longhorn-manager.*"}`);
ArgoCD sync state (`argocd_app_info{name="longhorn-extras"}`); attached volume count
(`count(longhorn_volume_state{state="attached"})`); healthy volume count
(`count(longhorn_volume_robustness{robustness="Healthy"})`); total volume capacity gauge
(`sum(longhorn_volume_capacity_bytes)`); Longhorn manager memory timeseries
(`container_memory_working_set_bytes{namespace="longhorn-system",container=~"longhorn-manager.*"}`).
All panels use real Mimir data with `X-Scope-OrgID: lab`; panels show "No data" naturally when
Longhorn is not running (ADR-0004, on-demand component). Extended `tests/longhorn.bats` with
assertions for scrape block presence, scrape target, dashboard file existence, KSM query with
`longhorn-system` namespace, Mimir datasource, uid, and no fabricated data. Updated
`docs/dependency-tree.md` with Longhorn observability note (Alloy scrape + dashboard).
(auto/longhorn-dashboard)

## PR

#333
