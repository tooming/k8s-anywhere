# Lab — Kargo promotion-pipeline dashboard + observability metrics

**Lab — Kargo promotion-pipeline dashboard + observability metrics**
(CHARTER **Core Values** §"Real observability only"; ADR-0023; follows the
on-demand dashboard precedent from `lab-inkless.json`). Kargo api, controller,
and webhooks-server expose controller-runtime Prometheus metrics (port 8080 per
chart v1.2.0). The kargo NetworkPolicy previously had no observability ingress
allow. Added `allow-kargo-metrics-ingress.yaml` to
`gitops/kargo/networkpolicy/kustomization.yaml` (ingress TCP 8080 from
`namespaceSelector: kubernetes.io/metadata.name: observability`; `podSelector:
{}` covers all kargo pods; mirrors the existing kyverno/trivy NP allow
pattern). Added `prometheus.scrape "kargo"` block to
`gitops/platform/observability-alloy.yaml` (static target
`kargo-api.kargo.svc.cluster.local:8080`; `scrape_interval = "30s"`; mirrors
the adjacent `velero` / `argo_rollouts` scrape pattern). New
`grafana/dashboards/lab-kargo.json` ("Lab — Kargo (GitOps Promotion)") modelled
on `lab-kyverno.json` stat-row: kargo-api pod running (KSM); kargo-controller
running (KSM); Kargo Memory (cAdvisor); ArgoCD sync state; about panel
documenting on-demand behavior; Stage reconcile rate timeseries
(`controller_runtime_reconcile_total{controller=~"stage.*"}`); Freight creation
rate timeseries; Warehouse reconcile rate timeseries. All panels use real Mimir
data with `X-Scope-OrgID: lab` (ADR-0004). Panels show "No data" naturally when
Kargo is not running. Extended `tests/kargo.bats` with eight new assertions:
scrape block `"kargo"` present; scrape target address; NP kustomization references
new allow file; allow file exists; allow file targets TCP 8080 from observability;
`lab-kargo.json` exists; dashboard references `controller_runtime_reconcile_total`;
no fabricated data. Updated `docs/dependency-tree.md` with Kargo observability note.

## PR

PR #317 — https://github.com/tooming/k8s-lab/pull/317
