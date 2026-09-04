# Lab — Cloud Control Plane dashboard (PR auto/cloud-control-plane-dashboard)

**ROADMAP item:** 🟢 Lab — Cloud control-plane (moto / ACK / KRO) dashboard (CHARTER Objective O5)

Delivered the "Lab — Cloud Control Plane (moto / ACK / KRO)" Grafana dashboard as the
last missing always-on-component dashboard, closing the CHARTER O5 observability gap.

## Files added

| File | Purpose |
|------|---------|
| `grafana/dashboards/lab-cloud-control-plane.json` | 21-panel dashboard; three subsections (moto / ACK S3 / KRO); all data from KSM, cAdvisor, ArgoCD, and Loki sources already scraped by Alloy (ADR-0004) |
| `docs/done/2026-06-13-cloud-control-plane-dashboard.md` | This file |

## Files modified

| File | Change |
|------|--------|
| `tests/observability.bats` | 13 new assertions: file exists, uid, three subsection headings, Mimir + Loki datasources, kube_pod_status_phase + container_memory_working_set_bytes + argocd_app_info queries present, no fabricated data, no unscraped controller-runtime metrics, dependency-tree mention |
| `docs/dependency-tree.md` | Added cloud-control-plane dashboard note in the Notes section |
| `ROADMAP.md` | Item marked `[x]` |

## Dashboard structure

Three subsections following the `lab-vault.json` stat-row pattern:

**moto (namespace `moto`)** — Pod Running / Memory / CPU / Restarts / ArgoCD Synced

**ACK S3 (namespace `ack-system`)** — same five stats + Loki logs panel filtered to
`{namespace="ack-system"} |= "Bucket"` (shows live `ack-demo-bucket` reconcile activity)

**KRO (namespace `kro`)** — same five stats + Loki logs panel for RGD reconcile activity
(`{namespace="kro"}`); "KRO Resources ArgoCD Synced" stat uses `kro-resources` app
(the Application that deploys the `S3BucketClaim` RGD + `app-data` instance)

## No HTTPRoute / stack-health.json update

The cloud-control-plane dashboard is a Grafana dashboard accessed inside Grafana, not
a standalone service with its own `*.127.0.0.1.nip.io` HTTPRoute. The `lab-ui-check.sh`
only validates host-based HTTPRoutes against the Lab UIs panel, so no `stack-health.json`
row is added (same pattern as the Kyverno dashboard). The moto entry (`moto.127.0.0.1.nip.io`)
is already present in the stack-health Lab UIs panel from the moto HTTPRoute.

## Deferred (follow-up planner items)

- **ACK / KRO controller-runtime scrape jobs** — if ACK S3 or KRO pods expose metrics
  at `:8080/metrics`, a follow-up planner item adds the Alloy scrape job and extends
  this dashboard with `controller_runtime_reconcile_total` and workqueue panels.

## PR

https://github.com/tooming/k8s-anywhere/pull/201
