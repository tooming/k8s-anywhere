# Lab — s3manager (S3 Browser) dashboard

**ROADMAP item:** `auto/s3manager-dashboard`
**CHARTER Objective:** O5 (due 2026-09-30 — every always-on component has a real-metric Grafana dashboard)
**PR:** auto/s3manager-dashboard

## What was built

New `grafana/dashboards/lab-s3manager.json` — "Lab — s3manager (S3 Browser)" dashboard.

`cloudlena/s3manager` exposes no Prometheus metrics of its own. All panels use KSM +
cAdvisor data already scraped by Alloy — no new scrape job needed (ADR-0004).

Panels:
- **s3manager Running** — `kube_deployment_status_replicas_available{namespace="storage",deployment="s3manager"}` (KSM stat)
- **ArgoCD Sync State** — `argocd_app_info{name="s3manager", sync_status="Synced"}`
- **Memory Usage (MiB)** — `container_memory_working_set_bytes{namespace="storage",container="s3manager"}` (cAdvisor stat)
- **CPU Usage Rate** — `rate(container_cpu_usage_seconds_total{namespace="storage",container="s3manager"}[5m])` (cAdvisor timeseries)
- **Memory Working Set timeseries** — same metric over time

The `s3.127.0.0.1.nip.io:8000` row already exists in `grafana/dashboards/stack-health.json`
— no new Lab UIs panel row added (`make lab-ui-check` unaffected).

## Files changed

| File | Change |
|------|--------|
| `grafana/dashboards/lab-s3manager.json` | New dashboard |
| `tests/observability.bats` | 8 new assertions (file exists, uid, mimir datasource, `kube_deployment_status_replicas_available`, `container_memory_working_set_bytes`, `container_cpu_usage_seconds_total`, no fabricated data, dependency-tree mention) |
| `docs/dependency-tree.md` | Added s3manager dashboard note to the Notes section |
| `ROADMAP.md` | Item marked `[x]` |
| `docs/done/2026-06-22-s3manager-dashboard.md` | This file |
