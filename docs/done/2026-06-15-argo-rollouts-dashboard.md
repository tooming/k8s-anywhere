# Argo Rollouts dashboard + Alloy scrape job (PR auto/argo-rollouts-dashboard)

**ROADMAP item:** 🟢 Argo Rollouts dashboard + Alloy scrape job (CHARTER Objective O1 + O5,
deferred from `auto/argo-rollouts-controller` per the 400-line budget rule)

Delivers the two deferred pieces from the Argo Rollouts controller PR: the Alloy
scrape job that collects controller-runtime metrics from `:8090`, and the Grafana
dashboard that visualises them with real Mimir data (ADR-0004).

## Files added

| File | Purpose |
|------|---------|
| `grafana/dashboards/lab-argo-rollouts.json` | "Lab — Argo Rollouts (Progressive Delivery)" — 10-panel dashboard: controller running, rollouts-dashboard running, ArgoCD sync state, memory, restarts, reconcile rate timeseries, Rollout phase distribution (Healthy/Paused/Degraded), canary weight gauge |
| `docs/done/2026-06-15-argo-rollouts-dashboard.md` | This file |

## Files modified

| File | Change |
|------|--------|
| `gitops/platform/observability-alloy.yaml` | Added `prometheus.scrape "argo_rollouts"` block targeting `argo-rollouts-metrics.argo-rollouts.svc.cluster.local:8090` at 30s interval |
| `tests/argo-rollouts.bats` | Removed "deferred" note from header; added 9 new assertions covering the scrape job and dashboard (scrape target present, metrics referenced, no placeholder data) |
| `docs/dependency-tree.md` | Added `argorolloutsctrl → alloy` scrape edge to Mermaid graph; added two integration-edge rows (Alloy scrape + Grafana dashboard); updated Argo Rollouts Notes entry to confirm scrape and dashboard are live |
| `ROADMAP.md` | Item marked `[x]` |

## Dashboard panels and their metric sources

| Panel | Metric | Source |
|-------|--------|--------|
| Controller Running | `kube_deployment_status_replicas_available{namespace="argo-rollouts", deployment="argo-rollouts"}` | KSM |
| Rollouts Dashboard Running | `kube_deployment_status_replicas_available{namespace="argo-rollouts", deployment="argo-rollouts-dashboard"}` | KSM |
| ArgoCD Synced | `argocd_app_info{name=~"argo-rollouts.*", sync_status="Synced"}` | ArgoCD scrape |
| Memory (MiB) | `container_memory_working_set_bytes{namespace="argo-rollouts"}` | cAdvisor |
| Restarts (max) | `kube_pod_container_status_restarts_total{namespace="argo-rollouts"}` | KSM |
| Reconcile rate /s | `controller_runtime_reconcile_total{namespace="argo-rollouts", controller="rollout"}` | Argo Rollouts scrape |
| Rollout Phase: Healthy/Paused/Degraded | `rollout_phase{phase=…}` | Argo Rollouts scrape |
| Active Canary Weight (%) | `rollout_canary_weight` | Argo Rollouts scrape |

Phase and canary-weight panels show "no data" naturally until a Rollout resource exists
in the cluster — this is correct ADR-0004 behaviour (no placeholder substitution).

## No stack-health.json change needed

The `rollouts.127.0.0.1.nip.io:8000` row was added to the Lab UIs panel in the
controller PR (`auto/argo-rollouts-controller`). The Grafana dashboard has no web UI
of its own separate from the Rollouts dashboard already listed.
