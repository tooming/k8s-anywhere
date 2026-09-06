# ADR-0041 — Remove the observability stack entirely (supersedes ADR-0006, ADR-0034)

**Status.** Adopted. Removes Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy,
kube-state-metrics, and node-exporter as workloads, with no replacement. Per
explicit maintainer direction ("full removal, no replacement") after the
change was flagged against the two binding ADRs it supersedes.

---

## Context

[ADR-0006](adr-0006-grafana-native-git-sync.md) (Grafana, native Git Sync) and
[ADR-0034](adr-0034-lgtmp-observability-stack.md) (the LGTM(P) internals —
Mimir, Loki, Tempo, Pyroscope, Alloy — plus kube-state-metrics and
node-exporter) together decided this lab's entire observability pipeline:
metrics, logs, traces, and continuous profiling, unified by one collector and
presented through one dashboard layer.

The maintainer directed a full, unreplaced removal of this pipeline. Per
CLAUDE.md's ADR discipline, this is flagged explicitly rather than silently
implemented: observability is not a peripheral component here. It is named as
one of the lab's core learner **Goals** in CHARTER.md ("the observability
pipeline (metrics, logs, traces, profiles)"), it backs an entire **Objective**
(O5, "every always-on component has a real-metric dashboard"), it is the data
source for Argo Rollouts' SLO-gated canary analysis (ADR-0020), and every
other component in this repo currently carries its own Grafana dashboard file
and Alloy `NetworkPolicy` scrape-ingress rule. Removing it is not a
same-shape swap the way ADR-0040's ingress-controller replacement was — there
is no successor absorbing the role. This ADR records that as a deliberate,
accepted narrowing of the lab's scope, not an oversight.

---

## Decision

Remove, as ArgoCD-managed workloads, with no replacement:

- **Grafana** (ADR-0006) — the dashboard/UI layer.
- **Mimir, Loki, Tempo, Pyroscope, Alloy** (ADR-0034) — the LGTM(P) stack and
  its collector.
- **kube-state-metrics, node-exporter** (ADR-0034) — the two exporters that
  existed solely as Alloy scrape targets, with no independent role once Alloy
  is gone.

Every dependent piece is removed alongside them, not left as dead
configuration:

- Every `grafana/dashboards/*.json` file (the entire `grafana/` tree) — a
  dashboard with no Grafana to render it and no Mimir/Loki/Tempo/Pyroscope to
  back its queries is not a real artifact, it is fabricated-looking dead
  weight (ADR-0004 concern by omission).
- The `observability` and `node-exporter` namespaces, their NetworkPolicy
  overlays, their governance LimitRange overlays, and their ApplicationSet
  list-generator entries.
- Every other namespace's `allow-*-from-observability`/`allow-alloy-*`/
  `allow-*-metrics-ingress` NetworkPolicy rule (Alloy scrape ingress, egress to
  Mimir/Loki/Tempo) — dead egress/ingress paths to a namespace that no longer
  exists.
- The CI dashboard-coverage machinery this stack existed to keep honest:
  `scripts/o5-dashboard-coverage-check.sh`, `scripts/observability-tests-check.sh`
  (the `tests/observability.bats` frozen-monolith guard), `tests/dashboard-coverage.bats`,
  `tests/drift-o5-dashboard-coverage-check.bats`, and every other component's own
  "dashboard exists" / "Alloy metrics ingress" bats assertions.
- `scripts/grafana-gitsync-bootstrap.sh` and its Makefile target (ADR-0006's
  Git Sync bootstrap step no longer has anything to bootstrap).

## Argo Rollouts loses its SLO gate (ADR-0020 impact, not superseded)

ADR-0020's capstone canary strategy gates each weight step on a Mimir-backed
`success-rate` `AnalysisTemplate` (`gitops/argo-rollouts/analysistemplates/success-rate.yaml`).
With Mimir gone, that data source is gone. This ADR removes the
`AnalysisTemplate` and the `analysis:` steps from `gitops/apps/capstone/rollout.yaml`,
leaving the canary as **weight/pause-only progressive delivery** — Argo
Rollouts still shifts traffic in stages (10% → 50% → 100%) via Traefik's
`TraefikService` (ADR-0040), it just no longer auto-halts on a measured
success-rate regression. ADR-0020 itself is not superseded (Argo Rollouts
stays; the controller, dashboard, and weight-based canary mechanism are
unchanged) — this is recorded here because it's a direct, mechanical
consequence of this ADR's removal, not an independent decision about Argo
Rollouts.

## CHARTER impact

This ADR requires — and this same change lands — edits to CHARTER.md:

- The "observability pipeline (metrics, logs, traces, profiles)" learner Goal
  is removed.
- Objective **O5** ("every always-on component has a real-metric dashboard")
  is removed outright — there is no dashboard layer left to measure against.
- Objective **O1**'s "real-metric Grafana dashboard" requirement is dropped
  from its measurement criteria (Kyverno/Argo Rollouts/Velero/Trivy Operator
  keep their Application + ADR + bats-coverage requirements).
- Objective **O3**'s stateful-DR namespace list drops `observability` (the
  namespace no longer exists).
- The "Docs & dashboards don't drift" Core Value is removed (no more Grafana
  Lab UIs panel to keep in sync — README's own Endpoints table becomes the
  sole UI-discovery source, already cross-checked by `make lab-ui-check`
  independent of Grafana).
- "Target end-state" narrations naming "the full LGTMP observability stack",
  "real-metric Grafana dashboard", and "Grafana shows its metrics & logs" in
  the capstone inner-loop description are rewritten to describe the
  now-shorter loop.

## What does not change

- **Velero** (ADR-0021) stays — cluster/PVC backup is unrelated to
  observability specifically; only the `observability` namespace's own daily
  Schedule is removed (the namespace is gone), the other four (`data`,
  `tidb`, `capstone`, `vault`) are untouched.
- **Argo Rollouts** (ADR-0020) stays, per the impact note above — the
  controller, dashboard, and weight-based canary mechanism are unchanged.
- **Traefik / ADR-0040** stays — ingress is an orthogonal concern; this ADR
  does not touch it.
- **KEDA** (ADR-0029) stays — its RabbitMQ-queue-depth `ScaledObject` demo
  does not depend on Mimir (it polls RabbitMQ's own management API directly).
  KEDA's Prometheus-expression scaler *type* still exists in the product but
  this lab's own demo does not use it, so nothing here is removed for KEDA.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0006](adr-0006-grafana-native-git-sync.md) | Superseded by this ADR. |
| [ADR-0034](adr-0034-lgtmp-observability-stack.md) | Superseded by this ADR. |
| [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) | Not superseded — impacted. Loses its Mimir-backed AnalysisTemplate SLO gate; canary becomes weight/pause-only. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | The removal itself is in service of this ADR — a dashboard or scrape config pointing at a deleted backend is exactly the kind of not-real artifact ADR-0004 exists to prevent. |
| [ADR-0021](adr-0021-velero-backup-restore.md) | The `observability` namespace's daily backup Schedule is removed alongside the namespace; the other four stateful namespaces' Schedules are untouched. |

---

## Files

| Path | Role |
|------|------|
| `gitops/platform/observability-{alloy,grafana,ksm,loki,mimir,node-exporter,pyroscope,tempo}.yaml` | Removed — the eight Application manifests this ADR removes |
| `gitops/platform/node-exporter-extras.yaml` | Removed — node-exporter namespace pre-creation |
| `gitops/observability/`, `gitops/node-exporter/` | Removed — the workload manifests + NetworkPolicy overlays for both namespaces |
| `gitops/governance/observability/`, `gitops/governance/node-exporter/` | Removed — governance LimitRange overlays |
| `gitops/argo-rollouts/analysistemplates/` | Removed — the Mimir-backed `success-rate` AnalysisTemplate |
| `grafana/` | Removed in full — every dashboard JSON |
