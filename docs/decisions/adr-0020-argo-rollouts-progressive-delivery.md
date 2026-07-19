# ADR-0020 — Argo Rollouts for progressive delivery (SLO-gated canaries via Envoy Gateway API)

**Status.** Adopted. Decision taken by the architect routine in this RFC. Always-on
component. CHARTER **Objective O1** (one of four Tier 1 next-wave components,
due 2026-12-31).

---

## Context

CHARTER Goals name *progressive delivery (canary releases gated by real SLO
metrics, not timers)* as a learning objective, and the capstone vision wires
*Argo Rollouts canaries on real Mimir SLOs → Envoy routes the canary slice*.

Today the lab has no progressive-delivery layer: a new image rolls out via
ArgoCD's standard `RollingUpdate` Deployment strategy — all pods replaced as
soon as the new ReplicaSet reaches `minAvailable`. There is no traffic-split,
no SLO gate, no automatic rollback.

The two CNCF-graduated progressive-delivery controllers are **Argo Rollouts**
(graduated 2024-11) and **Flagger** (graduated 2024-04).

---

## Decision

Adopt **Argo Rollouts** as the lab's progressive-delivery controller,
integrating with **Envoy Gateway** (ADR-0008) via the Gateway API
TrafficRouter plugin and pulling SLO metrics from **Mimir** (already scraped
by Alloy).

### Chart + version

- **Chart:** `argo/argo-rollouts` `2.41.0` (`appVersion: 1.9.0`; pin lives in
  `gitops/platform/argo-rollouts.yaml`'s `targetRevision` — this note read
  "v2.40.x" until the 2026-07-18 audit corrected it to the actual pin; see
  [§Re-evaluation log](#re-evaluation-log) for the current CVE status of this
  pin).
- **Source:** `https://argoproj.github.io/argo-helm`
- **Namespace:** `argo-rollouts` (new namespace; PSA label `restricted` —
  controller is non-root-capable per upstream Helm chart).

### Footprint controls

```yaml
controller:    { replicas: 1, resources: { limits: { memory: 128Mi } } }
dashboard:     { enabled: true, replicas: 1, resources: { limits: { memory: 64Mi } } }
```

Total: ~150-200 MiB. Dashboard enabled because it is a real Grafana-adjacent
learning artifact (the canary state visualisation) — wire its HTTPRoute via
`gitops/argo-rollouts/route.yaml` (`rollouts.127.0.0.1.nip.io`).

### Traffic-router plug-in (Envoy Gateway integration)

Install the **Gateway API TrafficRouter plug-in**:

```yaml
controller:
  trafficRouterPlugins: |
    - name: argoproj-labs/gatewayAPI
      location: https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/releases/download/v0.5.0/gatewayapi-plugin-linux-amd64
```

This makes `spec.strategy.canary.trafficRouting.plugins.argoproj-labs/gatewayAPI`
work against an Envoy Gateway `HTTPRoute` — the plug-in rewrites the route's
`backendRefs.weight` field on each step. ADR-0008 (Envoy Gateway / Gateway API)
is the prerequisite; both stay declarative.

### AnalysisTemplate from Mimir

Standard `prometheus`-provider AnalysisTemplate sourcing Mimir:

```yaml
spec:
  metrics:
  - name: success-rate
    interval: 30s
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://mimir-query-frontend.observability.svc.cluster.local:8080/prometheus
        headers:
        - key: X-Scope-OrgID
          value: lab
        query: |
          sum(rate(http_requests_total{namespace="{{args.namespace}}",code!~"5.."}[1m]))
          /
          sum(rate(http_requests_total{namespace="{{args.namespace}}"}[1m]))
```

The `X-Scope-OrgID: lab` header matches the single-tenant config used by the
existing Mimir Application; the existing Kiali datasource (ADR-0012) uses
the same pattern.

### Capstone integration

The capstone Deployment (`gitops/apps/capstone/deployment.yaml`) gains a
`Rollout` overlay (separate file, not an in-place Deployment swap — keeps
the pre-rollouts code reviewable). Canary strategy:

```yaml
strategy:
  canary:
    canaryService: capstone-canary
    stableService: capstone-stable
    trafficRouting:
      plugins:
        argoproj-labs/gatewayAPI:
          httpRoute: { name: capstone, namespace: capstone }
    steps:
    - setWeight: 10
    - pause: { duration: 60s }
    - analysis: { templates: [{ templateName: success-rate }], args: [{ name: namespace, value: capstone }] }
    - setWeight: 50
    - pause: { duration: 60s }
    - analysis: { templates: [{ templateName: success-rate }], args: [{ name: namespace, value: capstone }] }
    - setWeight: 100
```

### Observability

Controller exposes Prometheus metrics on `:8090/metrics`. Add Alloy
`prometheus.scrape "argo-rollouts"`. Dashboard
`grafana/dashboards/lab-argo-rollouts.json`: rollout phase distribution,
analysis-run pass/fail counts, canary weight by Rollout name, controller
reconcile rate.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/argo-rollouts/networkpolicy/` (ADR-0016).
  Allows: ingress TCP 8090 from `observability` (Alloy scrape); ingress TCP
  3100 from `envoy-gateway-system` (dashboard HTTPRoute); egress TCP 8080 to
  `observability` (Mimir AnalysisTemplate queries); egress to kube-apiserver
  via baseline.
- PSA label `restricted` (no carve-out needed).

---

## Why Argo Rollouts (not Flagger)

- **Same operator family as ArgoCD.** ADR-0001 anchors the lab on ArgoCD;
  Rollouts integrates as a first-class `kind: Rollout` resource that ArgoCD
  shows in the same dashboard.
- **Gateway API traffic-router plug-in is first-party.** The
  `rollouts-plugin-trafficrouter-gatewayapi` is published by argoproj-labs
  and tracks the Gateway API spec ADR-0008 already uses. Flagger's Gateway
  API support is also present, but Rollouts' plug-in model is closer to the
  ADR-0008 north-star of "everything is a Gateway API HTTPRoute".
- **Built-in dashboard.** Rollouts ships a UI (visualises canary steps in
  real time) that pairs with the Grafana dashboard for the "see the canary"
  learning objective. Flagger has no equivalent.
- **CNCF graduated** alongside Flagger — neither carries project-risk.

---

## Scope & exceptions

**In scope** — the lab's progressive-delivery controller; the AnalysisTemplate
catalogue (start with `success-rate`, add `latency-p95` and `error-rate-by-route`
as follow-up planner items); the capstone `Rollout` overlay (the first real
canary in the lab).

**Out of scope (this RFC):**

- Migrating *every* Deployment to a Rollout. Only capstone gets a Rollout in
  this RFC's executor follow-up; other workloads remain Deployments unless a
  follow-up RFC opts them in.
- Argo Rollouts notifications (Slack / webhook on analysis failure).
- Experiment / BlueGreen strategies — canary only, since canary is the
  CHARTER-named learning objective.

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0020-argo-rollouts-progressive-delivery.md` | This ADR |
| `gitops/platform/argo-rollouts.yaml` | Auto-synced ArgoCD `Application` for the controller + dashboard |
| `gitops/argo-rollouts/route.yaml` | Envoy HTTPRoute `rollouts.127.0.0.1.nip.io` |
| `gitops/argo-rollouts/analysistemplates/success-rate.yaml` | Mimir-backed AnalysisTemplate |
| `gitops/apps/capstone/rollout.yaml` | First real canary in the lab |
| `gitops/argo-rollouts/networkpolicy/kustomization.yaml` | Default-deny overlay |
| `gitops/platform/observability-alloy.yaml` | New `argo-rollouts` scrape job |
| `grafana/dashboards/lab-argo-rollouts.json` | Real-metric dashboard (Objective O5) |
| `tests/argo-rollouts.bats` | Clusterless tests: Application shape, plug-in pinned, AnalysisTemplate shape, scrape job present |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Rollouts land as ArgoCD-synced manifest edits — Rollout CRs alongside Deployments. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single-replica controller per ADR-0005; production runs HA. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | AnalysisTemplate queries hit real Mimir metrics; dashboard reads real `argo_rollouts_*` counters. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica controller; recreate from manifest. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Gateway API plug-in writes `weight` on the capstone HTTPRoute — no second ingress layer. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `argo-rollouts` namespace gets default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Controller runs under `restricted`; no carve-out. |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — Argo Rollouts CVE(s) in pinned `v1.9.0` kept (audit #520)

**Trigger.** Routine architect CVE sweep found `argoproj/argo-rollouts` shipped
`v1.9.1`, whose release notes name `CVE-2026-35469` (a `google.golang.org/grpc`
dependency bump) as the fix, closing issue #4667 — which itself reports a
broader set of unpatched vulnerabilities (1 critical, 3 high, 4 medium, 1 low
per its linked ArtifactHub security report) against `v1.9.0`, the app version
this lab's pinned chart currently ships.

**Decision: keep chart pin `2.41.0` (`appVersion: 1.9.0`).** Not groundable yet
— this lab deploys Argo Rollouts via the `argo/argo-rollouts` Helm chart, not
the raw app binary, and the chart repo (`argoproj/argo-helm`) has not published
a release tracking `appVersion >= 1.9.1`; `argo-rollouts-2.41.0` (`appVersion:
1.9.0`) is still the newest chart tag as of this audit. Bumping `targetRevision`
today would not change what's actually deployed — asserting a fixed posture
with nothing newer to pin to would be the fabrication ADR-0004 forbids.

**Flip condition.** `argo-helm` publishes a chart release whose `appVersion` is
`>= 1.9.1` (or whichever later tag first includes the CVE-2026-35469 fix) —
bump `gitops/platform/argo-rollouts.yaml`'s `targetRevision` to it, update
`tests/argo-rollouts.bats`'s pin assertion, and this log entry's "kept" status.

### 2026-07-19 — Argo Rollouts CVE-2026-35469 converted to an image-tag pin (RFC #552)

**Trigger.** Re-check of the 2026-07-18 flip condition: `argo-helm` still has not
published a chart release tracking `appVersion >= 1.9.1` (`argo-rollouts-2.41.0`
remains the newest chart tag). The flip condition as written has not fired — but
this repo already has a precedent this audit hadn't considered: pinning the
*running image* independently of the chart's own `appVersion` default, the same
technique `gitops/platform/observability-grafana.yaml` uses (`image.tag:
"13.0.1"` on top of `chart: grafana / targetRevision: 12.7.2`). The
`argo/argo-rollouts` chart's `values.yaml` exposes the identical override for
both `controller.image.tag` and `dashboard.image.tag`.

**Decision: Convert.** `targetRevision` stays `2.41.0` (unchanged — that's the
chart/template version), but `gitops/platform/argo-rollouts.yaml`'s
`valuesObject` now pins `controller.image.tag: "v1.9.1"` and
`dashboard.image.tag: "v1.9.1"`, matching the actual fixed release. This isn't
a reversal of the 2026-07-18 "not groundable" finding — the chart genuinely
still can't be bumped — it's a different, narrower lever that was available the
whole time and wasn't evaluated.

**Verification note (ADR-0004).** The `quay.io` registry API was unreachable
from the architect routine's sandbox (egress policy blocks it); the `v1.9.1`
image's existence was grounded indirectly — the `v1.9.1` git tag is real
(fetched real file content at that ref) and `argoproj/argo-rollouts`'s own
tag-triggered release workflow builds+pushes
`quay.io/argoproj/argo-rollouts:${{ github.ref_name }}` and
`quay.io/argoproj/kubectl-argo-rollouts:${{ github.ref_name }}` as part of the
same pipeline that published the (live, fully-populated) `v1.9.1` GitHub
Release. Not a direct manifest check — see RFC #552 for the full reasoning. If
a future run can reach the registry directly, confirm the tag pulls and update
this note.
