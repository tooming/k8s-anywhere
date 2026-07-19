# ADR-0028 — cert-manager for TLS certificate lifecycle

**Status.** Adopted. Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
is new ground, not a supersession). Always-on component. New CHARTER Goal ("automated
TLS certificate lifecycle") — no existing Objective covers it; ROADMAP items below
carry the buildable scope.

---

## Context

Every north-south route in the lab (`gitops/*/route.yaml`, ~20 `HTTPRoute`s fronted by
Envoy Gateway per [ADR-0008](adr-0008-envoy-gateway-not-traefik.md)) is plain HTTP —
`http://<name>.127.0.0.1.nip.io:8000`. There is no TLS anywhere in the ingress path: the
shared `Gateway` (`gitops/network/gateway.yaml`) declares a single `protocol: HTTP` port
80 listener, and `cert-manager` is explicitly *avoided* elsewhere in the repo today
(`gitops/platform/tidb-operator.yaml`: "Skip admission webhook — avoids cert-manager
dependency in a lab").

This is a real gap against the CHARTER Vision ("the most complete production-shaped
cloud-native platform") and the "north-south ingress via the Gateway API" Goal: every
production Kubernetes platform terminates TLS at the edge, and cert-manager is the
CNCF-graduated (2022-02), de-facto standard for automating certificate issuance and
rotation in-cluster — arguably as fundamental to a "complete" platform curriculum as
the secrets-flow or admission-policy Goals already covered. No ADR has previously
evaluated or rejected it; this is new ground, not a reversal.

**Why this can't just be "add a self-signed Secret and move on":** doing that once,
by hand, teaches nothing about the actual Goal here — *automated, renewed-without-
intervention* certificate lifecycle is the point (mirrors why ADR-0009/0021 chose
managed operators over one-off manifests for their respective concerns).

---

## Decision

Adopt **cert-manager** as the lab's always-on TLS certificate lifecycle manager, using
the **official Helm chart**.

### Chart + version

- **Chart:** `cert-manager` v1.20.x (chart version tracks app version 1:1 for this
  project, unlike most charts in this repo — pin the latest 1.20.x patch at executor
  pickup; v1.20.3 confirmed to exist via the upstream repo's tags as of this ADR).
- **Source:** `https://charts.jetstack.io` (the project's long-standing official Helm
  repository).
- **Namespace:** `cert-manager`.
- **CRDs via the chart itself** (`crds.enabled: true` in the `valuesObject`) — no
  separate imperative `kubectl apply -f crds.yaml` step, keeping day-2 CRD management
  inside the GitOps loop per [ADR-0001](adr-0001-gitops-over-terraform-helm.md).

### PSA profile — `restricted`, no carve-out needed

Verified directly against the pinned chart's `values.yaml` (fetched via
`git sparse-checkout` per the sparse-clone technique documented in this ROADMAP's
2026-07-15 network-access note — `charts.jetstack.io`'s index is proxy-blocked in an
executor's sandbox but the chart's own git repo is reachable): the controller,
webhook, and cainjector components **all** default to pod-level
`runAsNonRoot: true` + `seccompProfile.type: RuntimeDefault` and container-level
`allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]` +
`readOnlyRootFilesystem: true` — the full `restricted` PSS profile, with no chart
override needed. This is unusual for a first-cut component in this lab (most needed a
carve-out row in ADR-0017 initially) and is a deliberate reason to prefer cert-manager
over rolling a bespoke solution: the CNCF-graduated project already ships
production-grade pod hardening by default.

### Footprint controls (12 GB budget)

Chart ships no default resource limits (`resources: {}` for all three components). Per
[ADR-0005](adr-0005-spof-recreate-over-ha.md) (single-host, recreate-over-HA) and
matching the modest-limits style [ADR-0019](adr-0019-kyverno-admission-engine.md) set
for Kyverno:

```yaml
resources:            { limits: { memory: 128Mi } }   # controller
webhook:
  resources:           { limits: { memory: 64Mi } }
cainjector:
  resources:           { limits: { memory: 64Mi } }
```

Total cap: ~256 MiB combined limits — lighter than any of the four Tier 1 next-wave
components individually (Kyverno's admission controller alone caps at 256Mi).

### Certificate strategy — self-signed root CA, not public ACME

The lab's default path is `127.0.0.1` / `*.nip.io` on localhost — not
internet-reachable, so ACME HTTP-01/DNS-01 challenges (Let's Encrypt) cannot work
there, and the Oracle cloud backend ([ADR-0026](adr-0026-cloud-agnostic-infrastructure.md)/
[ADR-0027](adr-0027-first-cloud-backend-oracle-always-free-k3s.md)) has no stable
public hostname to issue against either (it uses the OCI instance's ephemeral public
IP, not a domain). A **self-signed root CA**, bootstrapped once via cert-manager's own
two-step pattern, works identically on every backend — satisfying
"cloud-agnostic by construction" — and is the standard approach for internal/lab PKI
(the same trust trade-off every local-HTTPS tool, e.g. `mkcert`, makes explicit):

1. A `ClusterIssuer` of type `selfSigned` (bootstrap-only, issues exactly one
   `Certificate`: the root CA itself).
2. A `Certificate` requesting that self-signed issuer produce a CA certificate
   (`isCA: true`), stored in a Secret.
3. A second `ClusterIssuer` of type `ca`, referencing that Secret — this is the
   issuer every real `HTTPRoute`'s TLS `Certificate` requests from.

Browsers will show an untrusted-CA warning until a learner imports the root CA locally
(documented as an explicit, expected step — same trade-off as any local dev-HTTPS
setup, not a lab bug).

### Observability

cert-manager's controller exposes Prometheus metrics on `:9402/metrics` by default.
Add an Alloy `prometheus.scrape "cert_manager"` job. Dashboard
`grafana/dashboards/lab-cert-manager.json`: controller/webhook/cainjector pod status,
ArgoCD sync state, certificate count by `Ready` condition
(`certmanager_certificate_ready_status`), certificate expiry time
(`certmanager_certificate_expiration_timestamp_seconds`) — a real, useful "when does
each cert renew" panel, and ACME/ready request rate.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/cert-manager/networkpolicy/` (ADR-0016 fan-out):
  baseline + ingress TCP 10250 from kube-apiserver (the chart's webhook
  `securePort` default — confirmed against the pinned chart's `values.yaml`; mirrors
  the existing apiserver `ipBlock` pattern) + ingress TCP 9402 from `observability`
  (metrics scrape — all three components expose on this port).
- PSA labels `restricted` on the `Namespace` (see above — no carve-out needed).

---

## Scope & exceptions

**In scope (this ADR, split across ROADMAP items per rule #9's ≤400-line guidance):**

- The cert-manager engine itself + the self-signed root CA bootstrap (`ClusterIssuer`
  ×2 + root `Certificate`) — fully additive, does not touch the existing HTTP-only
  traffic path, buildable and clusterless-verifiable in one item.
- A **new** `HTTPS` listener (port 443) on the existing shared `Gateway`, a wildcard
  `Certificate` for `*.127.0.0.1.nip.io` referenced by that listener's `tls` block, and
  the `frontdoor` tooling's `:8443 → cluster :443` port mapping — additive alongside
  the existing HTTP listener (never removes it), so every current HTTP URL keeps
  working unchanged; HTTPS becomes available, not mandatory. A follow-up item, not
  bundled with the engine, per the size guidance.

**Out of scope (this ADR):**

- Migrating every `HTTPRoute` to require/redirect-to HTTPS. Both HTTP and HTTPS stay
  available; forcing a redirect is a separate, later decision once the HTTPS path is
  proven.
- Real ACME/Let's Encrypt issuance against the Oracle cloud backend's public IP —
  plausible future enhancement once that backend has a stable DNS name, but the
  self-signed root CA is the uniform, cloud-agnostic default for both backends today.
- mTLS between in-cluster services (that's Istio ambient's territory per
  [ADR-0012](adr-0012-istio-ambient-not-sidecar.md), on-demand, already built) — this
  ADR is north-south edge TLS only.

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — cert-manager CVE sweep kept (audit #517)

**Trigger.** Routine CVE sweep found no cert-manager-specific CVE against the
current `1.21.0` line. The only related findings were upstream Go-toolchain
CVEs (CVE-2026-24051, CVE-2025-68121, CVE-2026-27145, CVE-2026-42504,
CVE-2026-42507) that older cert-manager releases (`1.19.x`) picked up by
bumping their bundled Go version — all predate this lab's pin.

**Decision: keep chart pin `1.21.0`.** Confirmed `1.21.0` is the latest
released tag as of this audit (no newer patch exists yet); the Go-toolchain
CVEs that affected older `1.19.x` releases are already resolved by being on
`1.21.0`.

**Flip condition.** Revisit when a cert-manager security advisory names a
version at or above `1.21.0` as affected.

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md` | This ADR |
| `gitops/platform/cert-manager.yaml` | Auto-synced ArgoCD `Application` for the engine |
| `gitops/cert-manager/namespace.yaml` | PSA `restricted` labels |
| `gitops/cert-manager/networkpolicy/` | Default-deny overlay |
| `gitops/cert-manager/root-ca/` | `selfSigned` + `ca` `ClusterIssuer`s, root `Certificate` |
| `gitops/network/gateway.yaml` | HTTPS :443 listener (shipped; see `tests/cert-manager.bats`) |
| `gitops/network/certificates/wildcard-certificate.yaml` | `*.127.0.0.1.nip.io` `Certificate` (shipped; see `tests/cert-manager.bats`) |
| `scripts/bluegreen-frontdoor.sh` / `frontdoor-ensure.sh` | `:8443 → :443` port mapping (shipped; see `tests/frontdoor-https.bats`) |
| `gitops/platform/observability-alloy.yaml` | New `cert_manager` scrape job |
| `grafana/dashboards/lab-cert-manager.json` | Real-metric dashboard (Objective O5 pattern) |
| `tests/cert-manager.bats` | Clusterless tests: Application shape, chart pin, PSA labels, ClusterIssuer chain, scrape job, dashboard |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Engine + issuers + certificates land as ArgoCD `Application`s / plain manifests; CRDs installed via the chart, not `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) / [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica controller, modest memory caps — lab trade-off, not a production default. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Dashboard sources real `certmanager_certificate_*` counters only; no panel before the first `Certificate` actually issues. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | The HTTPS listener this ADR adds lives on the same shared `Gateway` ADR-0008 established. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `cert-manager` namespace gets its own default-deny overlay during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | First always-on component to land at `restricted` with zero carve-out — add a `cert-manager: restricted` row, reason "chart ships full restricted-compatible defaults." |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | Apache 2.0, CNCF graduated, no paid tier required. |
| [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) | Self-signed root CA (not backend-specific ACME) is what makes this work identically on localhost and the Oracle backend. |
