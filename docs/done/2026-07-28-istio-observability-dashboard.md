# Lab — Istio ambient mesh (`istio-system`) observability wiring: Alloy scrape + Grafana dashboard

(CHARTER **Objective O5**, due **2026-09-30**; O5 gap — planner gap-analysis sweep 2026-07-28,
all five prior "Now / next" items being gated on maintainer-confirmation issues #631/#632/#633.
`istio-system-extras` (`gitops/platform/istio-system-extras.yaml`) is auto-synced under
`gitops/bootstrap/root-app.yaml`'s recursive `gitops/platform/` watch — the same ALWAYS-ON
PSA-floor pattern as `kargo-extras`/`longhorn-extras` (namespace + privileged PSA labels
pre-created ahead of `make istio-up`, the empty namespace itself cheap to keep auto-synced) —
but unlike those two it had **no Grafana dashboard and no Alloy scrape wiring at all**: verified
directly, zero `grafana/dashboards/lab-istio*.json` files existed and `grep -rl "lab-istio"
tests/` returned nothing. `docs/dependency-tree.md`'s istio-system NetworkPolicy note already
anticipated this gap: `allow-istio-metrics-ingress.yaml` opens ingress TCP 15014 from
`observability` "for future istiod Prometheus scrape" — that scrape was never actually added to
`observability-alloy.yaml`. **No prerequisites — executor may pick up immediately.**)

Mirrored the `auto/longhorn-dashboard` / `auto/kargo-observability-dashboard` precedent exactly
(same always-present-namespace-but-component-may-be-off shape): added a
`prometheus.scrape "istiod"` block to `gitops/platform/observability-alloy.yaml` (static target
`istiod.istio-system.svc.cluster.local:15014`, `scrape_interval = "30s"`, mirroring the adjacent
`longhorn`/`kargo` blocks) — the scrape naturally returns no series until `make istio-up`
actually runs istiod (ADR-0004-compliant "No data" until then, same as every other on-demand
component's always-on scrape job). New `grafana/dashboards/lab-istio.json` (`uid: "lab-istio"`,
title "Lab — Istio Ambient Mesh") modelled on `lab-longhorn.json`'s stat-row: istiod control-plane
readiness via KSM (`kube_deployment_status_replicas_available{namespace="istio-system",
deployment=~"istiod.*"}`); ArgoCD sync state (`argocd_app_info{name="istio-system-extras",
sync_status="Synced"}`); ztunnel node readiness via KSM
(`kube_daemonset_status_number_ready{namespace="istio-system",daemonset=~"ztunnel.*"}`);
istio-cni node readiness via KSM (`kube_daemonset_status_number_ready{namespace="istio-system",
daemonset=~"istio-cni.*"}`); istiod XDS push rate (`rate(pilot_xds_pushes[5m])`) and istiod
memory (`container_memory_working_set_bytes{namespace="istio-system",container=~"discovery.*"}`)
timeseries once the scrape target exists. No HTTPRoute (istiod has no web UI of its own; Kiali
already has its own separate on-demand dashboard/route). New `tests/istio-observability.bats`
(clusterless structural, mirrors `tests/longhorn.bats`'s shape): scrape block presence + target;
dashboard file existence, uid, `istio-system` namespace reference, Mimir datasource, and no
fabricated data. Updated `docs/dependency-tree.md`'s istio-system entry with an Observability
(O5) note documenting the new scrape + dashboard wiring.

**ADR-0004 caveat:** this remote clusterless session cannot verify istiod's real exposed metric
names (`pilot_xds_pushes`, the `discovery` container name) against a live Istio control plane —
these are standard, well-documented Istio metric/container names for the pinned chart version,
but the KSM-based panels (control-plane readiness, ArgoCD sync, ztunnel/istio-cni readiness) are
the ones guaranteed to show real data with zero live-cluster dependency; the two istiod-specific
panels show "No data" harmlessly if a name is off until verified on `make istio-up`.

## PR

#824
