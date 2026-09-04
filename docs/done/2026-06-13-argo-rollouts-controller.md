# Argo Rollouts controller (PR auto/argo-rollouts-controller)

**ROADMAP item:** 🟢 Argo Rollouts controller (CHARTER Objective O1, RFC #154 / ADR-0020)
**PR:** https://github.com/tooming/k8s-anywhere/pull/190

Delivered the Argo Rollouts progressive delivery controller as an always-on ArgoCD
Application backed by the Gateway API TrafficRouter plug-in (ADR-0020 + ADR-0008).

## Files added

| File | Purpose |
|------|---------|
| `gitops/platform/argo-rollouts.yaml` | Auto-synced ArgoCD Application; chart `argo/argo-rollouts` v2.40.0; 1 controller + 1 dashboard replica; `argoproj-labs/gatewayAPI` v0.5.0 plug-in |
| `gitops/platform/argo-rollouts-extras.yaml` | Wave-0 Application pre-creating `argo-rollouts` namespace with PSA `restricted` labels + HTTPRoute |
| `gitops/platform/argo-rollouts-networkpolicy.yaml` | Wave-4 NP Application with `LoadRestrictionsNone` |
| `gitops/argo-rollouts/namespace.yaml` | PSA `restricted` (ADR-0017; no carve-out needed) |
| `gitops/argo-rollouts/route.yaml` | Envoy HTTPRoute `rollouts.127.0.0.1.nip.io` → dashboard :3100 |
| `gitops/argo-rollouts/networkpolicy/kustomization.yaml` | Kustomize overlay referencing shared baseline + 3 per-workload allows |
| `gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-metrics-from-observability.yaml` | Ingress TCP 8090 from observability (Alloy scrape) |
| `gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-dashboard-from-gateway.yaml` | Ingress TCP 3100 from envoy-gateway-system (dashboard HTTPRoute) |
| `gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-egress-mimir.yaml` | Egress TCP 8080 to observability (AnalysisTemplate SLO queries) |
| `tests/argo-rollouts.bats` | 35 clusterless structural tests |
| `docs/done/2026-06-13-argo-rollouts-controller.md` | This file |

## Files modified

| File | Change |
|------|--------|
| `grafana/dashboards/stack-health.json` | Added `rollouts.127.0.0.1.nip.io:8000` row to Lab UIs panel |
| `docs/dependency-tree.md` | ARGOROLLOUTS subgraph + Envoy/Mimir edges + sync-wave table rows + integration edges + Notes entry |
| `ROADMAP.md` | Item marked `[x]` |

## Deferred (follow-up planner items)

- **Alloy scrape job** (`argo-rollouts-metrics` job in `observability-alloy.yaml`) — NetworkPolicy ingress on :8090 is pre-wired, scrape job lands in a follow-up PR.
- **Grafana dashboard** (`grafana/dashboards/lab-argo-rollouts.json`) — deferred per executor split note (PR budget). Will cover rollout phase distribution, analysis-run outcomes, canary weight, controller reconcile rate.
- **Capstone Rollout overlay** — the next item in the ROADMAP (`auto/capstone-rollout`); waits for this controller PR to merge so Rollout CRDs exist.
