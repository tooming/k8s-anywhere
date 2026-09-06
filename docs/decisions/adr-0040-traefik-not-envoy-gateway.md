# ADR-0040 — Traefik for north-south ingress (supersedes ADR-0008)

**Status.** Adopted. Re-enables k3s's bundled Traefik at cluster creation; removes
Envoy Gateway as a workload entirely. Active in `infra/modules/k3d-cluster/`,
`gitops/network/`, and every `gitops/**/route.yaml` (now `ingressroute.yaml`).

---

## Context

[ADR-0008](adr-0008-envoy-gateway-not-traefik.md) chose Envoy Gateway over the
k3s-bundled Traefik as the lab's sole north-south ingress controller, reasoned
primarily from Gateway API maturity and a shared Envoy data plane with the
(never-adopted at the ingress layer — [ADR-0012](adr-0012-istio-ambient-not-sidecar.md)
uses ztunnel/waypoint, not Envoy Gateway) Istio ambient mesh.

Since then, ADR-0008's own re-evaluation log recorded a materially different
operating history than the "simplification" the original decision predicted:

- A **chronic full front-door outage class** (2026-08-07 entry): the single-replica
  control-plane pod repeatedly lost its own Kubernetes leader-election lease under
  ordinary apiserver latency on this lab's single-host Colima VM, `os.Exit`'d, and
  took down *every* `HTTPRoute` in the cluster on each restart — 17+ restarts in ~2h
  during one incident window. Fixed by disabling leader election outright, but the
  underlying lesson stands: a Gateway-API control plane carries meaningfully more
  moving parts (xDS server, a separate proxy Deployment, its own leader-election
  loop) than this lab's single-host, single-replica reality benefits from.
- **A held CRD-breaking upgrade since 2026-08-18** — `v1.9.0` has been available and
  repeatedly re-confirmed un-appliable without live-cluster verification this
  clusterless environment cannot perform, across at least three separate audit
  cycles (2026-08-18, 2026-09-03 re-checks). The chart has been effectively frozen
  on `v1.8.3` for a month purely because nothing in this environment can safely
  verify a Gateway API CRD version bump renders cleanly.
- **Sustained operational surface**: a dedicated `envoy-gateway-system` namespace,
  five hand-maintained `NetworkPolicy` objects for it (controller metrics, proxy
  metrics, proxy listener ingress, proxy xDS ingress/egress), a bespoke drift
  guard (`scripts/envoy-egress-allowlist-check.sh`) whose entire job is keeping a
  hand-maintained backend-egress allowlist in sync with every namespace that
  attaches an `HTTPRoute` — a class of bug (P1 for Harbor, then recurring for
  `tidb`/`longhorn-system`/`istio-system`/`kargo`) that exists *because* the
  ingress layer is a separate control plane the default-deny NetworkPolicy model
  has to explicitly punch holes for.

k3s already bundles Traefik, provisioned automatically unless disabled — the
exact controller ADR-0008 turned off at cluster creation. Traefik v3 (k3s's
bundled version on the `v1.36.4-k3s1` pin, [ADR-0030](adr-0030-pin-k3s-version-explicitly.md))
ships first-class Gateway-API-adjacent CRDs (`IngressRoute`, `TraefikService`,
`TLSStore`, `Middleware`, apiVersion `traefik.io/v1alpha1`) that cover every
capability this lab actually uses: host-based routing, TLS termination off a
single shared certificate, and weighted traffic splitting for Argo Rollouts
canaries. It runs as part of the k3s node process supervision (not a
separately-scheduled Deployment the lab's own GitOps has to keep healthy), and
needs no separate leader-election, xDS, or backend-egress-allowlist machinery.

---

## Decision

**Re-enable k3s's bundled Traefik** (`disable_traefik = false`,
`infra/modules/k3d-cluster/variables.tf`). **Remove Envoy Gateway as a workload
entirely** — no `envoy-gateway-system` namespace, no Envoy Gateway ArgoCD
Application, no shared `Gateway`/`GatewayClass` objects.

Route all external-facing traffic via Traefik's native **`IngressRoute`** CRD
(`traefik.io/v1alpha1`), one per app, replacing the former `HTTPRoute` objects
1:1. TLS termination uses a single cluster-wide **`TLSStore`** named `default`
referencing the same wildcard certificate ADR-0028 already produces — every
`IngressRoute` opts in with an empty `tls: {}` stanza, preserving the "shared
gateway, no per-route TLS config" ergonomics ADR-0008 established. Argo
Rollouts canary weighting (ADR-0020) moves from the `argoproj-labs/gatewayAPI`
plugin to Argo Rollouts' **built-in Traefik integration**
(`trafficRouting.traefik.weightedTraefikServiceName`, backed by a
**`TraefikService`** CRD) — no plugin dependency at all, since Traefik support
ships in Argo Rollouts core.

---

## Why this doesn't just re-litigate ADR-0008's original table

ADR-0008's four-option table is still accurate on its own terms — Traefik's
first-class API historically was the annotation-driven `Ingress` object. What
changed is that **Traefik itself grew a native Gateway-API-adjacent CRD surface**
(`IngressRoute`/`TraefikService`/`TLSStore`) that wasn't a factor in 2026's
original comparison; this ADR is not choosing legacy `Ingress` + annotations,
it is choosing Traefik's own typed CRDs, which close most of the composability
gap the original table scored against it. The remaining, honest trade-offs:

| Property | Envoy Gateway (`HTTPRoute`) | Traefik (`IngressRoute`) |
|---|---|---|
| Standard Gateway API object | yes | no — Traefik-proprietary CRD (mirrors the annotation-style lock-in ADR-0008 originally avoided) |
| Cross-namespace shared entrypoint | explicit `Gateway`/`GatewayClass` + `parentRefs` | implicit — one controller, per-namespace `IngressRoute`, no shared parent object to reference |
| Separate control-plane workload to operate | yes (Deployment, leader election, xDS) | no — runs as part of k3s's own node supervision |
| Weighted canary traffic | Argo Rollouts plugin (`argoproj-labs/gatewayAPI`) | Argo Rollouts core (`trafficRouting.traefik`) |
| Backend-egress allowlist maintenance burden | yes (`scripts/envoy-egress-allowlist-check.sh`, a P1-incident-derived guard) | not needed — Traefik ingress traffic is sourced from `kube-system`, a pre-existing trusted namespace, and the from-gateway `NetworkPolicy` rules move there without a route-registry to keep in sync (see below) |

The honest cost being accepted: **losing the standard Gateway API vocabulary**
(a real ADR-0008 win, now given up) in exchange for **removing an entire
separately-operated control plane** on a single-host lab where that control
plane has caused two of this repo's most-discussed incident classes
(front-door 502s; Harbor's #631/#633 egress-allowlist gap). On a multi-tenant
production cluster with a platform team, ADR-0008's original trade would still
be correct — Gateway API's role separation matters there. On this lab's single
operator, single host, the operational simplicity wins.

---

## Known risk — not live-verified

Per [ADR-0004](adr-0004-no-fabricated-content.md), this decision is **not**
being asserted as live-cluster-verified — this session has no running cluster
to apply these manifests against. Specific unverified points, flagged
explicitly rather than silently assumed correct:

- **Argo Rollouts' `TraefikService` CRD group.** Argo Rollouts' own published
  example (`argoproj.github.io/argo-rollouts/features/traffic-management/traefik/`)
  still shows `apiVersion: traefik.containo.us/v1alpha1` for `TraefikService` —
  the legacy Traefik v2 CRD group — while Traefik v3 (k3s's bundled version)
  registers CRDs under `traefik.io/v1alpha1`. A known upstream compatibility gap
  exists between Argo Rollouts' controller and the `traefik.io` group for this
  object (`argoproj/argo-rollouts#3615`). This ADR wires the capstone `Rollout`
  and its `TraefikService` under `traefik.io/v1alpha1` for consistency with
  every other Traefik CRD this lab defines, but **the first live canary run
  after this migration must confirm Argo Rollouts (chart `2.43.0`,
  `gitops/platform/argo-rollouts.yaml`) actually reconciles a
  `traefik.io/v1alpha1 TraefikService`** — if it does not, the fallback is
  either bumping Argo Rollouts to a version that supports the `traefik.io`
  group, or defining the `TraefikService` under the legacy
  `traefik.containo.us/v1alpha1` group instead (Traefik v3 can be configured to
  still watch both groups). Tracked as a flip condition below.
- **Default `TLSStore` scoping.** This ADR assumes a single `TLSStore` named
  `default` (namespace `lab-gateway` — reusing the namespace ADR-0008's
  GatewayClass/Gateway used to occupy, not `kube-system`; Traefik's CRD
  provider watches `TLSStore` objects across all namespaces, so it need not be
  co-located with the Traefik pod itself) is picked up cluster-wide as the
  default certificate for the `websecure` entrypoint with no further
  per-`IngressRoute` `tls` field beyond the empty `tls: {}` opt-in. This
  matches Traefik's documented behavior but has not been confirmed against a
  running cluster.

---

## What does not change

- Hostname strategy (`*.127.0.0.1.nip.io`, ADR-0008's nip.io rationale) —
  unchanged, `IngressRoute` host matching works identically.
- [ADR-0016](adr-0016-default-deny-networkpolicy.md)'s default-deny floor —
  unchanged; every app's `allow-*-from-gateway` `NetworkPolicy` still exists,
  now sourced from `kube-system` (Traefik's namespace) with a
  `podSelector: app.kubernetes.io/name: traefik` instead of
  `envoy-gateway-system` / `app.kubernetes.io/component: proxy`.
- [ADR-0028](adr-0028-cert-manager-tls-lifecycle.md)'s wildcard certificate —
  unchanged; the same `Certificate`/`Secret` now backs a `TLSStore` instead of
  a Gateway `listener.tls.certificateRefs`.
- [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md)'s canary shape
  (weight steps, Mimir-backed analysis gates) — unchanged; only the traffic-
  routing backend (Traefik native vs. the Gateway API plugin) changes.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Superseded by this ADR. |
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Traefik re-enablement is a k3d bootstrap flag (Terraform, day-0 seam) exactly as Envoy Gateway's removal is — no separate ArgoCD Application needed for the ingress controller itself, since it now ships with k3s. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | Every from-gateway allow rule is retargeted to `kube-system`/`traefik`, not removed. |
| [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) | Canary traffic-routing backend swapped to Argo Rollouts' built-in Traefik support; the plugin dependency is dropped. |
| [ADR-0028](adr-0028-cert-manager-tls-lifecycle.md) | TLS termination moves from the Gateway's HTTPS listener to a Traefik `TLSStore`, same certificate. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Traefik still serves every namespace from one shared controller — same decoupled shape as ADR-0008's shared `Gateway`, just without a dedicated CRD to represent the sharing. |

---

## Files

| Path | Role |
|------|------|
| `infra/modules/k3d-cluster/variables.tf` | `disable_traefik` default flipped to `false` |
| `gitops/network/traefik-tls-store.yaml` | Cluster-wide `TLSStore default` referencing the existing wildcard certificate Secret |
| `gitops/*/ingressroute.yaml` (formerly `route.yaml`/`httproute.yaml`) | Per-app `IngressRoute`, one per former `HTTPRoute` |
| `gitops/apps/capstone/rollout.yaml` | `trafficRouting.traefik.weightedTraefikServiceName` + `TraefikService` replacing the `gatewayAPI` plugin config |
| `gitops/**/networkpolicy/allow-*-from-gateway.yaml` | Retargeted from `envoy-gateway-system`/`proxy` to `kube-system`/`traefik` |
