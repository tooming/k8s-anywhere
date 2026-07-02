# Lab — Harbor OCI registry dashboard + observability metrics

**Lab — Harbor OCI registry dashboard + observability metrics** (CHARTER
**Core Values** §"Real observability only"; ADR-0024 §observability; follows
the on-demand dashboard precedent from `lab-inkless.json`;
**prerequisite: `auto/harbor-application` merged ✓**). Harbor exposes
Prometheus metrics via its built-in exporter. Enable metrics by patching
`gitops/platform/harbor.yaml` `valuesObject` with `metrics.enabled: true`
(creates a `harbor-metrics` Service; executor must verify the exact port
at pickup — chart v1.16.x uses port 9090 on the `harbor-metrics` Service by
default, but check `kubectl get svc harbor-metrics -n harbor` or the chart
source). Add `allow-harbor-metrics-ingress.yaml` to
`gitops/harbor/networkpolicy/kustomization.yaml` (ingress TCP from
`namespaceSelector: kubernetes.io/metadata.name: observability` on the
verified metrics port; mirrors the existing `allow-trivy-metrics-from-observability`
NP pattern). Add `prometheus.scrape "harbor"` block to
`gitops/platform/observability-alloy.yaml` (static target
`harbor-metrics.harbor.svc.cluster.local:<port>` where `<port>` is the
verified metrics port; `scrape_interval = "30s"`; mirrors the adjacent
`inkless` / `trivy_operator` scrape pattern). New
`grafana/dashboards/lab-harbor.json` ("Lab — Harbor (OCI Registry)") modelled
on `lab-kyverno.json` stat-row: harbor-core pod running (KSM
`kube_deployment_status_replicas_available{namespace="harbor",deployment=~"harbor-core.*"}`);
ArgoCD sync state (`argocd_app_info{name="harbor-extras"}`); image artifact
total (`harbor_artifact_total` by project); image push/pull counts
(`harbor_artifact_total{operation=~"push|pull"}`). All panels real Mimir data
with `X-Scope-OrgID: lab` (ADR-0004 — panels not yet emitting series show
"No data" naturally; Harbor is on-demand). No new HTTPRoute row needed —
`harbor.127.0.0.1.nip.io` row already exists; `make lab-ui-check`
unaffected. Extend `tests/harbor.bats`: scrape block `"harbor"` present in
`observability-alloy.yaml`; `lab-harbor.json` exists; dashboard references
`harbor_artifact_total`; no fabricated data. Update
`docs/dependency-tree.md` with Harbor observability note. `docs/done/`
entry required. `make ci` must pass. (auto/harbor-observability-dashboard)

## PR

#318
