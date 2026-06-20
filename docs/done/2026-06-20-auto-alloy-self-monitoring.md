# Lab — Grafana Alloy self-monitoring dashboard + self-scrape

- [x] 🟢 **Lab — Grafana Alloy self-monitoring dashboard + self-scrape** (CHARTER **Objective O5**, auto/alloy-self-monitoring)

Added `prometheus.scrape "alloy_self"` block to `gitops/platform/observability-alloy.yaml` (static target `alloy.observability.svc.cluster.local:12345`, `scrape_interval = "30s"`). The Alloy Helm chart creates a stable ClusterIP Service on port 12345, so no chart changes are needed.

New `grafana/dashboards/lab-alloy.json` ("Lab — Grafana Alloy (Collector)") with 6 panels:
- Alloy pod running (KSM `kube_deployment_status_replicas_available{namespace="observability",deployment=~"alloy.*"}`)
- ArgoCD sync state (`argocd_app_info{name="alloy",sync_status="Synced"}`)
- Active scrape targets (`prometheus_sd_discovered_targets{job="alloy"}`)
- Samples ingested /s (`rate(prometheus_tsdb_head_samples_appended_total{job="alloy"}[5m])`)
- Remote write bytes/s to Mimir (`rate(prometheus_remote_storage_sent_bytes_total{job="alloy"}[5m])`)
- Component evaluation time rate (`rate(alloy_component_evaluation_seconds_sum{job="alloy"}[5m])`)

All panels use real Mimir data (ADR-0004); any panel shows "No data" naturally until the self-scrape emits a series. No HTTPRoute — port 12345 is metrics-only so `make lab-ui-check` is unaffected.

9 new bats tests in `tests/observability.bats`; `docs/dependency-tree.md` updated with Alloy self-scrape and dashboard integration edges.
