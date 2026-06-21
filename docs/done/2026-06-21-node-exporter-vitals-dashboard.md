# Lab — Node Exporter cluster-vitals dashboard

**CHARTER Objective O5** (due 2026-09-30). PR: auto/node-exporter-vitals-dashboard.

- [x] **Lab — Node Exporter cluster-vitals dashboard** (CHARTER **Objective O5**, due 2026-09-30) — Added `grafana/dashboards/lab-node-exporter.json` ("Lab — Node Vitals") covering host-level infrastructure metrics. No new Alloy scrape job needed — node-exporter metrics are already collected via the `prometheus.scrape "node_exporter"` block in `gitops/platform/observability-alloy.yaml`.

## Panels delivered

| Panel | Metric |
|-------|--------|
| Node Exporter Pod Running (stat) | `kube_daemonset_status_number_ready{daemonset=~".*node-exporter.*"}` |
| ArgoCD Sync State (stat) | `argocd_app_info{name="node-exporter", sync_status="Synced"}` |
| Node Uptime (stat) | `time() - node_boot_time_seconds` |
| CPU Usage (gauge) | `1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))` |
| Memory Pressure (gauge) | `1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)` |
| Disk Usage by Mount (gauge) | `1 - (node_filesystem_avail_bytes{fstype!~"tmpfs\|overlay"} / node_filesystem_size_bytes)` by device |
| CPU Usage over Time (timeseries) | same CPU expression as range vector |
| Memory Available vs Total (timeseries) | `node_memory_MemTotal_bytes` + `node_memory_MemAvailable_bytes` |
| Network Throughput excl. loopback (timeseries) | `rate(node_network_receive_bytes_total{device!="lo"}[5m])` + `rate(node_network_transmit_bytes_total{device!="lo"}[5m])` by interface |

All panels use real Mimir data with `uid: mimir` datasource. Panels show "No data" naturally until node-exporter emits series (ADR-0004). No HTTPRoute — node-exporter has no web UI; `make lab-ui-check` is unaffected.

## Files changed

| Path | Change |
|------|--------|
| `grafana/dashboards/lab-node-exporter.json` | New dashboard (9 panels) |
| `tests/observability.bats` | 11 new bats assertions for the dashboard |
| `docs/dependency-tree.md` | Integration table row for lab-node-exporter.json |
| `docs/done/2026-06-21-node-exporter-vitals-dashboard.md` | This file |
| `ROADMAP.md` | Item marked `[x]` |
