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

---

## Files

| Path | Role |
|------|------|
| `gitops/platform/envoy-gateway.yaml` | ArgoCD Application — installs Envoy Gateway chart (currently pinned `v1.8.2`) from `docker.io/envoyproxy/gateway-helm` |
| `gitops/platform/lab-gateway.yaml` | ArgoCD Application — applies `GatewayClass` + `Gateway` objects from `gitops/network/gateway.yaml` |
| `gitops/network/gateway.yaml` | `GatewayClass eg` + shared `Gateway eg` in `lab-gateway` ns; `allowedRoutes: All` |
| `gitops/network/argocd-route.yaml` | `HTTPRoute` for the ArgoCD UI (reference example) |
| `gitops/*/route.yaml` | Per-app `HTTPRoute` objects; each cross-references `parentRefs: [{name: eg, namespace: lab-gateway}]` |
