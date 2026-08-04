# ADR-0012 — Istio ambient mesh + Kiali on-demand (not sidecar)

**Status.** Adopted. Decision taken in RFC #59. Manifests landed in
`gitops/platform/istiod.yaml`, `gitops/platform/ztunnel.yaml`, and peers /
`gitops/platform/kiali.yaml` (non-auto-synced ArgoCD `Application`s) and brought up
with `make istio-up` / `make kiali-up`.

---

## Context

The lab's always-on ingress layer (ADR-0008, Envoy Gateway) handles north-south traffic.
The charter calls for an east-west **service mesh** to complete the learning objective:
mTLS between services, traffic policy, observability without code changes.

Two broad Istio deployment modes exist, plus lighter alternatives:

| Option | Rationale |
|--------|-----------|
| **Istio sidecar mode** | The classic approach: `istio-proxy` (Envoy) injected as a sidecar into every Pod. Proven in production but adds a proxy container + 50–100 MB per Pod to the already-full 12 GB VM; requires per-namespace/per-pod injection annotations; a single misconfigured injection label breaks all traffic for that namespace. |
| **Linkerd** | Very light (Rust micro-proxy, ~10 MB/sidecar) but sidecar-based; departs from the Envoy data plane chosen for ingress (ADR-0008) → two data plane technologies, two Envoy-vs-Rust mental models. |
| **Cilium eBPF mesh** | No sidecar; eBPF-based. Requires a kernel ≥ 5.10 and changes the CNI, which is not the lab's primary learning target. The lab already uses the k3s default CNI (flannel); swapping CNI is a disruptive Day-0 change. |
| **Istio ambient mode** ✅ | No per-Pod sidecar injection. A node-level **ztunnel** (Rust, ~50 MB/node) handles L4 mTLS; an optional **waypoint proxy** (Envoy) handles L7 policy per-namespace on demand. Lighter footprint, simpler namespace enrollment (`istio.io/dataplane-mode: ambient` label only), same Envoy data plane as ADR-0008, and actively production-ready as of Istio 1.22. |

---

## Decision

Deploy **Istio in ambient mode** as the lab's service mesh, on-demand (not auto-synced).
Add **Kiali** as the mesh observability UI (on-demand, depends on Istio).

Istio's four ambient-mode Helm charts are used in order:

| Chart (repo `https://istio-release.storage.googleapis.com/charts`) | Component | Purpose |
|---|---|---|
| `istio/base` | CRDs + cluster-scoped resources | `istio-system` namespace, CRDs (`VirtualService`, `AuthorizationPolicy`, `PeerAuthentication`, …) |
| `istio/istiod` | Control plane | xDS push, certificate authority (SPIFFE), mesh config |
| `istio/cni` | CNI plugin | Redirects Pod traffic to ztunnel without `NET_ADMIN` init containers |
| `istio/ztunnel` | Node-level L4 proxy | Per-node zero-trust tunnel; handles mTLS transparently |

Kiali is deployed from its **official Helm chart** (`kiali-server` from
`https://kiali.org/helm-charts`). It requires Istio to be up and running first.

All five ArgoCD `Application`s are **non-auto-synced** (no `automated:` block) — users
bring them up with `make istio-up` / `make kiali-up` and tear them down with
`make istio-down` / `make kiali-down`.

---

## Why ambient over sidecar

| Criterion | Ambient | Sidecar |
|-----------|---------|---------|
| **Memory overhead** | ~50 MB for one ztunnel per node (shared by all Pods on that node) | ~50–100 MB per Pod; the lab's ~20 always-on Pods would add ~1–2 GB |
| **Injection complexity** | Label the namespace; no per-Pod annotation needed | `istio-injection: enabled` label + `kubectl rollout restart` for existing Pods |
| **Broken injection risk** | No injection; missing labels = mesh opt-out, not breakage | A wrong injection label leaves the Pod without a sidecar and silently skips mTLS |
| **Data-plane consistency** | ztunnel (Rust, L4) + Envoy waypoint (L7, optional) — same Envoy engine as the north-south gateway (ADR-0008) | Envoy sidecar per Pod — same engine, but double the Envoy instances |
| **Production trajectory** | Ambient graduated to stable in Istio 1.22 (2024) | Still the incumbent; ambient is the strategic direction (Istio project statement) |
| **Lab learning value** | Teaches the *new* ambient model; sidecar is well-documented everywhere | Teaches the established model; less differentiated |

---

## Relationship to ADR-0008 (Envoy Gateway)

ADR-0008 chose Envoy Gateway for north-south ingress explicitly because Istio ambient uses
the same Envoy data plane, keeping one consistent engine across both layers. With ambient:

- **North-south**: Envoy Gateway (`gitops/platform/envoy-gateway.yaml`) handles ingress
  via `HTTPRoute` objects — unchanged.
- **East-west**: Istio ztunnel handles Pod-to-Pod mTLS at L4; optional Envoy waypoints
  handle L7 policy per namespace.
- The two roles remain **separate deployments** (ADR-0008 is not modified). What's shared
  is the data-plane engine and the `HTTPRoute` / Gateway API vocabulary — Istio 1.22+
  supports Gateway API natively.

---

## 12 GB budget — on-demand, not auto-synced

The always-on stack already occupies ~7 GB of the 12 GB VM. Istio ambient's footprint
estimate for the lab:

| Component | Approximate footprint |
|-----------|-----------------------|
| `istiod` control plane | ~200 MB |
| `istio-cni` DaemonSet (1 node effective) | ~30 MB |
| `ztunnel` DaemonSet (1 node effective) | ~50 MB |
| Kiali server | ~200 MB |
| **Total** | **~480 MB** |

This is well within the available headroom (~5 GB), but still significant enough that
running Istio + Longhorn + Artifactory simultaneously would be tight. Therefore:

- Istio and Kiali are **on-demand** (non-auto-synced), same pattern as TiDB and Artifactory.
- `make istio-up` / `make istio-down` and `make kiali-up` / `make kiali-down` give the
  user explicit control. A combined `make mesh-up` / `make mesh-down` target is acceptable
  if the manifest item chooses to fold them (executor's call per ROADMAP rule).
- A `bats` test asserts that none of the Istio/Kiali ArgoCD `Application`s have an
  `automated:` block (mirrors `tests/platform.bats` for Artifactory).

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | All Istio and Kiali components are deployed as ArgoCD `Application`s from official Helm charts. `helm install` is never run directly. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Ambient ztunnel is a node-level DaemonSet, not a single pod; decoupled by design. The lab accepts a single istiod replica (ADR-0005). |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single istiod replica on a single host — acceptable. Production runs ≥ 2 istiod replicas for HA. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Istio ambient shares Envoy as its L7 (waypoint) data plane; ADR-0008 chose Envoy Gateway for north-south partly in anticipation of this east-west layer. The Kiali UI is exposed via an Envoy `HTTPRoute` (`kiali.127.0.0.1.nip.io`). |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — Istio / Kiali CVE sweep kept (audit #516)

**Trigger.** Routine CVE sweep found two Istio security bulletins: the
ISTIO-SECURITY-2026-004 class (CVE-2026-47692, CVE-2026-47774, CVE-2026-47775
padding oracle in the OAuth2 filter's cookie decryption, CVE-2026-47220 crash
in the `%REQUESTED_SERVER_NAME%` formatter, and others in the same bulletin,
CVSS 7.5) affecting **1.30.1–1.30.2**, fixed in **1.30.3**; and the older
ISTIO-SECURITY-2026-001 class (CVE-2026-31837 JWKS fallback RSA key leak,
CVE-2026-26308 RBAC header-matcher bypass) affecting the **1.27.x/1.28.x/
1.29.x** lines, fixed in 1.27.8/1.28.5/1.29.1. No Kiali-specific CVE was found
for 2026 against the upstream `kiali-server` chart this lab uses (the one hit,
CVE-2025-13465, is a lodash prototype-pollution issue in the Red Hat OpenShift
Service Mesh downstream fork, a different distribution).

**Decision: keep chart pins `1.30.3` (base/istiod/cni/ztunnel) and `1.89.8`
(kiali-server).** `1.30.3` already carries the 1.30.1–1.30.2 fixes, and sits
far above the affected 1.27–1.29 range for the older bulletin. Kiali has no
applicable CVE at the current pin.

**Flip condition.** Revisit when a new Istio security bulletin names a
version at or above `1.30.3` as affected, or a Kiali-specific CVE is
published against the `kiali-server` chart (not a downstream OpenShift fork).

### 2026-07-23 — kiali-server `1.89.8` pin no longer resolves; Convert to `2.29.0` (audit #668)

**Trigger.** Not a CVE — a live-index availability break. An executor run found
`scripts/helm-chart-pin-check.sh` (the `drift` job in `ci.yml`) failing on a
clean `main` checkout with no relevant diff: `kiali.org/helm-charts` is
reachable, but its served index no longer lists `kiali-server` version
`1.89.8`. Confirmed not transient — `main`'s own CI run 4.5 hours earlier
passed this exact check. Verified directly (ADR-0004): `v1.89.8` is a real git
tag in `github.com/kiali/helm-charts` and is the **last pre-2.0 release** —
the next tag in the series is `v2.0.0`. Kiali shipped a real major release,
**Kiali 2.0** ("the first major Kiali release in over 5 years"), with named
breaking changes: namespace-visibility config moved to Discovery Selectors;
`.spec.kubernetes_config.cache_*` removed from the CRD; `spec.istio_namespace`
/ `spec.external_services.istio.root_namespace` removed. None of those touch
this lab's actual `valuesObject` (`auth.strategy`, `external_services.
prometheus.{url,custom_headers}`, `external_services.tracing.enabled`,
`deployment.resources`) — none of those keys appear in the breaking-change
list, and cross-checking `external_services.prometheus.url`/`custom_headers`
(the `X-Scope-OrgID` header this lab's multi-tenant Mimir needs) and
`external_services.tracing.enabled` against current (2026) Kiali docs/
community examples confirms both remain valid, unchanged config keys in
Kiali 2.x. Full reasoning and verification trail: RFC #668.

**Decision: Convert.** There is no smaller safe delta available — the entire
pre-2.0 line appears pruned from the live-served index, not just this one
patch, so "keep the pin" is not an option; the only real choice is which
currently-resolvable version to move to. Bump to `v2.29.0` (2026-07-13, the
newest verified-real tag), `valuesObject` unchanged (compatibility verified
above). Tracked as RFC #668 for the executor to implement.

**Flip condition.** Revisit when a Kiali-specific CVE is published against
`kiali-server` at or above `2.29.0`, or the chart repo prunes `2.29.0` itself
the same way it pruned `1.89.8` (in which case: bump again to whatever the
newest resolvable tag is at that time, same reasoning as this entry).

### 2026-07-28 — ISTIO-SECURITY-2026-005 (missed by the 2026-07-18 audit) kept, pin already safe (audit #778)

**Trigger.** Routine CVE sweep found a third Istio security bulletin,
**ISTIO-SECURITY-2026-005** (dated 2026-06-24 — three weeks *before* the
2026-07-18 audit above ran, but not cited by it), affecting
`1.30.1`–`1.30.2`/`1.29.4`–`1.29.5`/`1.28.8`–`1.28.9` (CVSS 7.5; includes a
DoS via HTTP/3 QPACK blocked decoding, a use-after-free in the `ext_authz`
filter, and a memory-exhaustion issue in the Zstd decompressor), fixed in
`1.30.3`/`1.29.5`/`1.28.9`. This is a correction to the audit *record*, not a
new upstream event this lab was exposed to unpatched.

**Decision: Keep.** This lab's pin (`1.30.3` across `istio-base`/`istiod`/
`istio-cni`/`ztunnel`, re-confirmed consistent across all four files) already
carries the `1.30.3` fix floor — the same target version the 2026-07-18
audit's -004 finding already justified, so no version change was ever
needed. **Flip condition:** unchanged from the 2026-07-18 entry — revisit
when a new Istio security bulletin names a version at or above `1.30.3` as
affected.

### 2026-08-04 — `kiali-server` `2.29.0` → `2.30.0`, CVE fix floor (planner-fallback currency check)

**Trigger.** The 2026-07-23 audit's flip condition ("revisit when a
Kiali-specific CVE is published against `kiali-server` at or above `2.29.0`")
fired. Verified directly (ADR-0004): a real clone of
`github.com/kiali/helm-charts` shows `v2.30.0` as a genuine stable tag past
the pinned `v2.29.0`; a real clone of the `kiali/kiali` app repo (versioning
tracks 1:1 with the chart, same as the prior audit) shows `git log
v2.29.0..v2.30.0` contains three named CVE fixes in Kiali's bundled frontend
dependencies: **CVE-2026-59877** (`protobufjs` → `7.6.5`), **CVE-2026-49978**
(`dompurify` → `3.4.7+`), and **CVE-2026-59869** (`js-yaml` → `4.3.0`) — each
affects versions up to and including `2.29.0`, fixed in `2.30.0`.

**Decision: Convert (bump to `2.30.0`).** The rest of the `v2.29.0..v2.30.0`
range is feature work (an opt-in OpenShift impersonation mode, Gateway API
TCPRoute/UDPRoute support, Ambient-mesh validation improvements) plus CI/chore
commits — none of it touches this lab's `valuesObject` keys (`auth.strategy`,
`external_services.prometheus.{url,custom_headers}`,
`external_services.tracing.enabled`, `deployment.resources`); the new opt-in
`auth.openshift.impersonation.*` block this lab doesn't set stays at its
(still-present) default. Same smallest-safe-delta reasoning as this lab's
other chart-pin bumps.

**Flip condition (next re-evaluation).** Revisit when a Kiali-specific CVE is
published against `kiali-server` at or above `2.30.0`, or the chart repo
prunes `2.30.0` itself (same as the 2026-07-23 entry's pattern — bump again to
whatever the newest resolvable tag is at that time).

---

## Files

| Path | Role |
|------|------|
| `gitops/platform/istio-base.yaml` | ArgoCD Application — chart `istio/base` (CRDs + namespace) |
| `gitops/platform/istiod.yaml` | ArgoCD Application — chart `istio/istiod` (control plane) |
| `gitops/platform/istio-cni.yaml` | ArgoCD Application — chart `istio/cni` (CNI plugin) |
| `gitops/platform/ztunnel.yaml` | ArgoCD Application — chart `istio/ztunnel` (node-level L4 proxy) |
| `gitops/platform/kiali.yaml` | ArgoCD Application — chart `kiali-server` from `https://kiali.org/helm-charts` |
| `gitops/kiali/route.yaml` | Envoy `HTTPRoute` for the Kiali UI |
| `Makefile` | `istio-up`, `istio-down`, `kiali-up`, `kiali-down` targets |
| `tests/platform.bats` | bats assertions: no `automated:` block on any Istio/Kiali Application |
