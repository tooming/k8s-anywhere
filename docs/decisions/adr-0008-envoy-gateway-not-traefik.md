# ADR-0008 — Envoy Gateway for north-south ingress (Gateway API, not Traefik / Kubernetes Ingress)

**Status.** Adopted. Shipped at cluster creation; active in `gitops/platform/envoy-gateway.yaml`,
`gitops/platform/lab-gateway.yaml`, and all `gitops/**/route.yaml` HTTPRoute objects.

---

## Context

Every lab service that needs to be reachable from the workstation (ArgoCD UI, Vault,
Grafana, the demo app, …) requires an ingress/routing layer between the host port and
the backing Kubernetes Service.

**k3s ships with Traefik** as its default ingress controller, provisioned automatically
unless explicitly disabled. Before any decision is made, the runtime already includes an
opinionated controller based on the legacy `networking.k8s.io/v1 Ingress` API.

Four options were on the table:

| Option | API | Rationale against |
|--------|-----|-------------------|
| **Keep Traefik** (k3s default) | `Ingress` (primary), CRD-based `IngressRoute` for extras | Traefik's first-class API is the old Ingress object with annotation-driven config — verbose, not composable across namespaces, and the lab's planned east-west path (Istio ambient) uses a different control plane; two routing systems with overlapping scope adds confusion. |
| **Nginx Ingress Controller** | `Ingress` only | Same legacy-API concern as Traefik; no Gateway API support in the OSS controller. |
| **Contour** | Gateway API (via HTTPProxy CRD) | Mature Gateway API support, but introduces a project-specific CRD (`HTTPProxy`) on top of the standard; adds a project for no material gain over Envoy Gateway. |
| **Envoy Gateway** ✅ | Gateway API (`HTTPRoute`, `GRPCRoute`, …) | First-class Gateway API implementation from the EnvoyProxy project; same Envoy data plane the lab plans to use for Istio ambient mesh east-west traffic; standard CRDs (no proprietary objects); OCI Helm chart; actively developed. |

---

## Decision

Disable k3s's built-in Traefik at cluster creation (`k3d cluster create … --k3s-arg '--disable=traefik'`).
Deploy **Envoy Gateway** as the sole north-south ingress controller, managed by ArgoCD
(ADR-0001). Route all external-facing traffic via standard **`kind: HTTPRoute`**
objects pointing at the shared `Gateway` in the `lab-gateway` namespace.

---

## Gateway API over Kubernetes Ingress

The Kubernetes SIG-Network graduated `Ingress` to stable but simultaneously introduced
the **Gateway API** as its intended successor, with richer semantics:

| Property | `Ingress` | Gateway API `HTTPRoute` |
|----------|-----------|------------------------|
| **Hostname-based routing** | yes (host field) | yes |
| **Cross-namespace routing** | no — rules live in the same namespace as the backend | yes — `parentRefs` + `allowedRoutes: All` |
| **Extensibility** | annotations only (controller-specific, not portable) | policy-attachment CRDs; typed filters (header modification, redirect, …) |
| **Role separation** | none — one resource governs infrastructure + routing rules | `GatewayClass` (infra owner) / `Gateway` (platform team) / `Route` (app team) |
| **Future-proof** | frozen | the basis for Istio Ambient, Envoy Gateway, and all new SIG-Network work |

Using `HTTPRoute` keeps app teams from touching infrastructure resources, keeps routing
rules co-located with the app manifests, and avoids the annotation-driven escape hatches
that couple routes to a specific controller implementation.

---

## Shared gateway, allowedRoutes: All

A **single `Gateway`** (`eg` in `lab-gateway`) with `allowedRoutes.namespaces.from: All`
lets any namespace attach an `HTTPRoute` without a platform-team approval step. Each app
owns its route file; the gateway is shared infrastructure.

This is consistent with ADR-0003 (decoupled, no single-pod SPOFs): the gateway
distributes traffic to per-namespace services without each service needing its own
load-balancer or ingress instance.

---

## Hostname strategy — `*.127.0.0.1.nip.io`

All lab service hostnames follow the pattern `<service>.127.0.0.1.nip.io`. The
`nip.io` wildcard DNS service resolves any `*.127.0.0.1.nip.io` to `127.0.0.1`, so
every hostname routes to the workstation's loopback interface — no `/etc/hosts`
edits, no local DNS server, and the pattern works out-of-the-box across machines.

The host port `8080` (Colima port-forward) terminates at the Envoy Gateway
`LoadBalancer` Service, which proxies to the appropriate backend per hostname.

---

## Why Envoy for the planned Istio ambient mesh

The planned east-west service-mesh layer (see Istio ambient in the context, to be
decided by a future ADR) uses **Envoy** as its data plane. Choosing Envoy Gateway as
the north-south layer today means:

- a single consistent data plane across ingress *and* mesh;
- operational familiarity (one Envoy config model to learn);
- a natural integration path where the same `HTTPRoute` resource is understood by both
  Istio's gateway API support and Envoy Gateway.

This is not a coupling decision — the two roles (north-south ingress vs east-west mesh)
remain separate deployments. It is a *simplification* decision: same engine, same API
vocabulary, same observability hooks.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | `envoy-gateway` and `lab-gateway` are ArgoCD Applications (sync-wave 0) — consistent with the GitOps-only workload rule. Traefik removal is a k3d bootstrap flag, not a separate workload. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | One shared `Gateway` serves all namespaces rather than per-service ingress replicas — decoupled, no duplicated infrastructure. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | The Gateway is a single replica on a single node — acceptable on a single-host lab. If the Gateway pod restarts, routes recover automatically; no active–active redundancy is warranted here. |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — Envoy Gateway CVE sweep kept (audit #515)

**Trigger.** Routine CVE sweep found five fixes that landed in chart `v1.8.2`
(xDS server auth bypass in `GatewayNamespaceMode`; Lua validator sandbox
path-normalization bypass; missing read lock on the wasm HTTP server cache
map; nil-dereference when a `SecurityPolicy` targets a `TCPRoute` without
`spec.authorization`; OCI layer extraction untrusted-tar-header memory
allocation) plus two from `v1.8.1` (cross-namespace `ReferenceGrant` bypass
via custom `backendRef`; wasm HTTP fetch gzip decompression without an
output-size limit).

**Decision: keep chart pin `v1.8.2`.** `gitops/platform/envoy-gateway.yaml`
is already pinned at the exact release that carries every fix found in this
sweep — no bump is groundable because there's nothing newer needed yet.

**Flip condition.** Revisit when a new Envoy Gateway security bulletin names
a version above `v1.8.2` as affected, or `v1.8.2` itself is later found
retroactively vulnerable to something not yet disclosed.

### 2026-07-23 — Envoy Gateway v1.8.3 bump, Convert (RFC #671)

**Trigger.** The 2026-07-18 flip condition fired: `v1.8.3` was found (a prior
cycle's PR #663, 2026-07-22T05:46 UTC, held off because the chart/image
hadn't been published to Docker Hub yet — 404 on `envoyproxy/gateway-helm:v1.8.3`).
Re-verified 2026-07-23: the GitHub release is live (published
2026-07-22T18:59:00Z, stable, not pre-release; changelog: dependency updates
plus a fix that rejects a TLS secret when its certificate and private key
don't match), and the Docker Hub OCI artifact resolves for real
(`tag_status: active`, digest
`sha256:cfb34ff4266c87a394cd6be5c13607a2dd47083aef771368302eaeaa99c4a0a9`,
`last_updated: 2026-07-22T18:57:28Z`, confirmed via
`https://hub.docker.com/v2/repositories/envoyproxy/gateway-helm/tags/v1.8.3`).

**Decision: bump chart pin `v1.8.2` → `v1.8.3`.** Same source, same
major.minor line — a same-source patch bump only, no architecture change.
`gitops/platform/envoy-gateway.yaml`'s `targetRevision` now reads `v1.8.3`.

**Flip condition.** Revisit when a new Envoy Gateway security bulletin names
a version above `v1.8.3` as affected, or `v1.8.3` itself is later found
retroactively vulnerable to something not yet disclosed.

### 2026-08-07 — Leader election disabled (chronic front-door 502 fix)

**Trigger.** The control-plane Deployment (`replicas: 1`, per this ADR's
"single replica … acceptable" call and [ADR-0005](adr-0005-spof-recreate-over-ha.md))
still ran controller-runtime's default Kubernetes leader election. On any
apiserver latency spike — routine on this lab's single Colima VM host (see
the on-demand-budget-incident and blue/green-contention project notes) — the
sole pod failed to renew its own lease within controller-runtime's tight
defaults (~10s renew deadline / 15s lease duration), logged
`leaderelection.go: error retrieving lease lock` / `leader election lost`,
and `os.Exit`'d, killing and restarting the only replica. Observed
repeatedly across sessions; most recently 17+ restarts in ~2h during the
#631/#633 investigation on 2026-08-07. Each restart is a full front-door
outage — every `HTTPRoute` behind the shared gateway 502s, not just one —
since there is no second replica to take over traffic while the pod
restarts.

**Decision: set `provider.kubernetes.leaderElection.disable: true`** in
`gitops/platform/envoy-gateway.yaml`'s Helm `valuesObject` (gateway-helm
`v1.8.3` exposes this via the `EnvoyGateway` config's `LeaderElection` type —
verified against the chart's rendered `EnvoyGateway` config, not just
`values.yaml`). With exactly one candidate, election arbitrates nothing;
disabling it removes the self-inflicted-restart failure mode by
construction rather than by loosening a timeout around it. The chart's
Deployment template hardcodes `livenessProbe`/`readinessProbe` with no
`.Values` override hook (checked directly in
`envoy-gateway-deployment.yaml`), so — unlike Harbor's probe-timeout fix,
PR #1040 — there was no probe knob available to loosen as a secondary
mitigation; moot here regardless, since the restarts were leader-election
process exits, not probe-triggered kills.

**Flip condition.** Revisit if the control plane ever moves to
`replicas > 1` (at which point leader election becomes meaningful again and
must be re-enabled), or if a future gateway-helm release changes where this
knob lives.

### 2026-08-18 — `v1.9.0` release found, kept — architect-fallback pass (recording an
executor-fallback finding already made in an earlier run)

**Trigger.** A routine upstream-release sweep (executor-fallback ARCHITECT pass,
`executor.prompt.md` STEP 6b) found `v1.9.0` — a real, stable release, GA'd
2026-08-15, published ahead of the exact chart tag this ADR's own `## Files`
table cites (`v1.8.3`). This is a **retroactive log entry**: a cycle in an
earlier run, the same day this release went GA (`auto/ksm-chart-8-3-1`, PR
#1204/its docs/done record), had already investigated this exact bump and
deliberately deferred it, but only recorded that decision in
`docs/done/2026-08-17-ksm-chart-8-3-1.md`, not in this ADR's own
self-tracking Re-evaluation log — the convention every other kept audit on
this page (and Longhorn's ADR-0013, TiDB's ADR-0032) follows. Re-verified
independently this cycle (not just re-stating the prior finding, ADR-0004):
the upstream changelog between `v1.8.3` and `v1.9.0` still names multiple
breaking changes, including a Gateway API CRD version bump requirement —
`gitops/platform/envoy-gateway.yaml`'s `targetRevision` is still `v1.8.3`,
unchanged since that earlier check.

**Decision: keep chart pin `v1.8.3`.** This is this lab's sync-wave-0,
always-on-core north-south ingress control plane — every `HTTPRoute` in the
cluster routes through it. A breaking CRD-version bump on a component this
critical needs `helm template`/`kubeconform`-against-live-CRDs verification
(or a live ArgoCD sync a human/live-cluster session watches) before landing;
this remote clusterless session has neither. Same judgment call this ADR's
own `v1.8.2`→`v1.8.3` Convert entry above used in reverse, and the same
convention ADR-0013's Longhorn hold and ADR-0032's TiDB hold already
establish: a real upstream release existing is not by itself groundable
without a way to verify the bump renders cleanly.

**Flip condition.** Revisit when a live-cluster or better-tooled session can
run `helm template envoyproxy/gateway-helm --version v1.9.0` against this
lab's actual Gateway API CRD versions and confirm no breaking change applies,
or when a security bulletin names a version above `v1.8.3` as affected
(shortening the timeline regardless of tooling availability).

---

## Files

| Path | Role |
|------|------|
| `gitops/platform/envoy-gateway.yaml` | ArgoCD Application — installs Envoy Gateway chart (currently pinned `v1.8.3`) from `docker.io/envoyproxy/gateway-helm` |
| `gitops/platform/lab-gateway.yaml` | ArgoCD Application — applies `GatewayClass` + `Gateway` objects from `gitops/network/gateway.yaml` |
| `gitops/network/gateway.yaml` | `GatewayClass eg` + shared `Gateway eg` in `lab-gateway` ns; `allowedRoutes: All` |
| `gitops/network/argocd-route.yaml` | `HTTPRoute` for the ArgoCD UI (reference example) |
| `gitops/*/route.yaml` | Per-app `HTTPRoute` objects; each cross-references `parentRefs: [{name: eg, namespace: lab-gateway}]` |
