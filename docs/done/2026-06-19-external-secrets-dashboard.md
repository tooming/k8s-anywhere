# 2026-06-19 — External Secrets dashboard + Alloy scrape

**Branch:** `auto/external-secrets-dashboard`
**PR:** TBD (opened by this run)
**ROADMAP item:** `External Secrets dashboard + Alloy scrape` (CHARTER Objective O5, due 2026-09-30)

## What was delivered

**Alloy scrape job** added to `gitops/platform/observability-alloy.yaml`:
- Job name `external_secrets`, target `external-secrets.external-secrets.svc.cluster.local:8080`
- 30 s scrape interval; mirrors the kyverno / trivy_operator / velero / argo_rollouts pattern
- No chart `valuesObject` change needed — ESO exposes controller-runtime metrics at `:8080/metrics` by default

**Grafana dashboard** `grafana/dashboards/lab-external-secrets.json` — "Lab — External Secrets":
- Stat: ESO controller running (`kube_deployment_status_replicas_available{namespace="external-secrets"}`)
- Stat: ArgoCD sync state (`argocd_app_info{name="external-secrets", sync_status="Synced"}`)
- Stat: sync error count (`externalsecret_sync_calls_total{status="error"}`)
- Timeseries: sync success rate by namespace (`externalsecret_sync_calls_total{status="success"}`)
- Timeseries: sync duration p95 (`externalsecret_sync_calls_duration_seconds_bucket`)
- All panels use real Mimir data with `uid: mimir` datasource; panels show "No data" naturally until ESO emits series (ADR-0004)
- No HTTPRoute — ESO has no web UI; `make lab-ui-check` unaffected

**`docs/dependency-tree.md`** updated with two new table rows:
- Alloy → External Secrets Operator scrape edge
- Grafana dashboard — Lab — External Secrets entry

**`tests/observability.bats`** extended with four new assertions:
1. `prometheus.scrape "external_secrets"` block present in `observability-alloy.yaml`
2. `grafana/dashboards/lab-external-secrets.json` file exists
3. Dashboard references `externalsecret_sync_calls_total`
4. No fabricated/placeholder data (ADR-0004)

## Why

CHARTER Objective O5 requires every always-on component to have a real-metric Grafana
dashboard by 2026-09-30. `external-secrets` is auto-synced in `gitops/bootstrap/root-app.yaml`
but had no Alloy scrape job and no dashboard — this closes that gap.
