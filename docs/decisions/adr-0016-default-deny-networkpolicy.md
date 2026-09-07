# ADR-0016 — Default-deny NetworkPolicy per namespace

**Status.** Adopted. Decision taken in RFC #82. Pilot namespace: `data`. **Fan-out is
complete** as of 2026-07-14 — every always-on namespace (plus the on-demand ones that
have landed) carries the two-policy floor; see §"Scope & exceptions" below for the
current enumeration and [docs/dependency-tree.md](../dependency-tree.md) (row 4, plus
the per-component prose) for the continuously-maintained live list, which is more
current than any static table in this ADR could stay.

---

## Context

[RFC #82](https://github.com/tooming/k8s-lab/issues/82) calls for a
deny-by-default, allow-by-exception network-segmentation model expressed in the
standard `networking.k8s.io/v1 NetworkPolicy` API. This requires:

1. A policy-capable CNI — originally covered by **ADR-0014** (Cilium, swapping
   out k3s-default Flannel + kube-router). ADR-0014 was removed entirely
   2026-09-07, no replacement — see "Cilium's removal" below for what enforces
   this ADR's policies now.
2. The policy fan-out itself: two baseline policies per namespace (deny-all +
   allow-DNS-and-apiserver) plus per-workload explicit-allow policies.

Without a policy-capable CNI every `NetworkPolicy` object lands declaratively
but is silently non-functional — exactly the "fabricated content" anti-pattern
ADR-0004 forbids. This ADR depends on the cluster's CNI actually enforcing
`networking.k8s.io/v1 NetworkPolicy` — true of k3s's bundled Flannel + kube-router
today (kube-router is the piece that enforces; Flannel is only the data plane).

### Cilium's removal (2026-09-07) — enforcement moved, the pattern didn't

Cilium (ADR-0014) was removed entirely 2026-09-07, no replacement — host capacity
found live with hard evidence (docs/incident-log.md) plus the maintainer's
"no replacement, aggressive simplification" direction this session. k3s's bundled
Flannel CNI + **kube-router** NetworkPolicy controller enforces this ADR's policies
now, as plain `networking.k8s.io/v1 NetworkPolicy` — the same API this ADR always
targeted, so no policy YAML needed to change shape.

The enforcement mechanics did change, though: under kube-router's iptables-based
`FORWARD`-chain enforcement, kube-proxy's ClusterIP DNAT happens first (in the
`nat` table's `PREROUTING` chain), so a NetworkPolicy rule evaluates against
already-DNAT'd traffic — the real backend pod's IP, not the ClusterIP. This is the
opposite order from Cilium's kube-proxy-free socket-LB datapath, which evaluated
policy *before* a ClusterIP was ever resolved to a backend pod. Practically: a
plain podSelector/namespaceSelector rule against the real destination pods now
works correctly, and needs none of the socket-LB/pre-DNAT ClusterIP-CIDR
workarounds Cilium required for Service-fronted egress. See
[`gitops/network/policies/allow-dns-and-apiserver.yaml`](../../gitops/network/policies/allow-dns-and-apiserver.yaml)'s
header comment for the full technical detail this paragraph summarizes.

---

## Decision

Adopt **deny-by-default, allow-by-exception** network segmentation for every
lab namespace, using the following pattern:

### 1. Two baseline policies in every namespace

| Name | Selector | policyTypes | Rule |
|------|----------|-------------|------|
| `default-deny-all` | `podSelector: {}` | `[Ingress, Egress]` | no rules (deny everything) |
| `allow-dns-and-apiserver` | `podSelector: {}` | `[Egress]` | UDP/TCP 53 to `kube-system` pods (`k8s-app: kube-dns`) plus DNS service frontends; TCP 443/6443 to the k3s API service/frontends |

These two are the universal floor — every namespace gets both. Together they
let a pod resolve DNS and reach the Kubernetes API while blocking all other
ingress and egress by default.

### 2. Per-workload explicit-allow policies

Named for the flow they permit (e.g. `allow-vault-from-eso`,
`allow-argocd-server-from-gateway`). One YAML file per flow, co-located with the
workload it serves (e.g. `gitops/vault/networkpolicy/allow-vault-from-eso.yaml`).
No catch-all "allow same namespace" — every edge is explicit.

### 3. Reusable templates

Two parameter-free template files under `gitops/network/policies/`:
- `default-deny.yaml` — the `default-deny-all` NetworkPolicy (namespace
  provided by the consuming Kustomize overlay)
- `allow-dns-and-apiserver.yaml` — the `allow-dns-and-apiserver` NetworkPolicy

Each namespace's Kustomize overlay sets `namespace:` in a patch so a single
`kustomization.yaml` plus a 3-line patch is all a new namespace needs.

### 4. Staged rollout — pilot then fan-out (complete)

| Phase | Scope | Rationale |
|-------|-------|-----------|
| **Pilot** (this ADR) | `data` namespace | RabbitMQ + Redis are self-contained, the existing "Lab — RabbitMQ" / "Lab — Redis" dashboards and `data-demo` load generator give immediate signal if a policy is wrong. (Historical: the `data` namespace, RabbitMQ, and Valkey — Redis's successor, ADR-0018 — were removed from the lab entirely 2026-09-06; the pilot itself, and the pattern it established, still stands.) |
| **Fan-out** (planner-groomed items, one namespace per executor run) | Every remaining always-on namespace, delivered via the `networkpolicy` `ApplicationSet` (`gitops/platform/networkpolicy-appset.yaml`, list-generator, wave 3, generated Applications at wave 4) | Sequential, one namespace per executor run so failures are isolated; the appset consolidated the standalone per-namespace Applications this pattern originally produced into one list, per RFC #82's spirit without one YAML file per namespace in `gitops/platform/`. |
| **Out of scope** | `kube-system` | Contains kube-dns, metrics-server, and the kubelet's SA issuer; flows are complex and a policy mistake here takes the cluster down. Unchanged since this ADR was adopted. |

---

## Why kube-router (formerly Cilium, ADR-0014)

Cilium was this lab's CNI/policy engine from adoption until its removal
2026-09-07 (ADR-0014, no replacement — see "Cilium's removal" above). k3s's
bundled Flannel + kube-router — the option ADR-0014 originally rejected — is
what actually enforces this ADR's `NetworkPolicy` objects today:

- k3s's bundled Flannel provides the data plane; kube-router (also bundled)
  is the piece that actually enforces standard `networking.k8s.io/v1
  NetworkPolicy` — without it, any policy placed would be silently
  non-functional, same risk Cilium's absence would have posed originally.
- What's given up versus Cilium: eBPF-datapath performance, `kubeProxyReplacement`,
  Hubble observability, and the richer `CiliumNetworkPolicy` L7 dialect. None of
  those were load-bearing for this ADR's actual decision (plain
  `networking.k8s.io/v1 NetworkPolicy`, never `CiliumNetworkPolicy`), so the
  removal cost this ADR nothing beyond the enforcement-order change described
  above.

---

## Why default-deny

- NIST SP 800-204C and the CNCF Cloud Native Security Whitepaper v2 both
  name "default-deny ingress + egress per namespace, with explicit allows" as
  the production bar. Pod Security Standards (ADR-0017) intentionally do not
  cover the network — `NetworkPolicy` is the dedicated control surface.
- Deny-egress-everything immediately breaks workloads because DNS (kube-dns)
  and API access become unreachable. The two-policy split (deny-all +
  allow-dns-and-apiserver) is the standard pattern that avoids this footgun.
- Pilot-then-fan-out is how every shop rolls deny-by-default without a
  Friday-night outage. The `data` namespace has the cleanest blast radius.

---

## Scope & exceptions

**Namespaces in scope — fan-out complete (2026-07-14).** As of 2026-09-07, this
lab is down to exactly 6 always-on namespaces, all carrying the two-policy floor:
`argocd`, `cert-manager`, `external-secrets`, `lab-demo`, `lab-gateway`, `vault`.
(Every other namespace this ADR previously enumerated — `ack-system`,
`argo-rollouts`, `capstone`, `capstone-pipeline`, `harbor`, `kargo`,
`kargo-project`, `kro`, `kyverno`, `moto`, `storage`, `trivy-system`, `velero`,
plus the earlier `data`, `observability`, `node-exporter`, `envoy-gateway-system`,
`istio-system`, `longhorn-system`, and `tidb`/`tidb-admin` — was removed from the
lab entirely, no replacement, across a series of 2026-09-06/2026-09-07 removals;
see each component's own ADR Status.) This list drifts as new components land —
treat [docs/dependency-tree.md](../dependency-tree.md) as the live source of
truth and this ADR as the *pattern*, not the enumeration.

**Carve-outs / special handling:**

| Namespace | Treatment | Reason |
|-----------|-----------|--------|
| `kube-system` | out of scope | DNS, metrics-server, API issuer — a mistake here brings the cluster down. Separate RFC. |
| `argocd` | single broad `podSelector: {}` intra-namespace allow (`allow-argocd-intra-namespace.yaml`) instead of one explicit per-flow policy per edge | Formalized 2026-07-15 (found via ROADMAP rule #9's coverage/hardening sweep) — ArgoCD hosts a single purpose-built, tightly-coupled multi-component stack (controller/server/repo-server/cache) with no independent tenants mixed in, and the manifest's own header comment carries this exact rationale. **General principle (to prevent this same gap recurring for a future namespace):** a namespace may use one broad intra-namespace allow instead of per-flow policies when every pod in it is part of the same single-tenant, purpose-built multi-component stack — the cross-namespace boundary is the security perimeter ADR-0016 protects; the intra-namespace convenience allow never widens *that* boundary. **Flip condition:** if a future namespace-scoped threat model requires intra-namespace segmentation, replace this with explicit per-flow policies per the ADR's general pattern. (This row also covered `harbor`, `observability`, `istio-system`, `longhorn-system`, and `tidb` until each of those components was removed from the lab entirely.) |

---

## Files this work touches

**Pattern (unchanged since the pilot):**

| Path | Role |
|------|------|
| `docs/decisions/adr-0016-default-deny-networkpolicy.md` | This ADR |
| `gitops/network/policies/default-deny.yaml` | Reusable deny-all template |
| `gitops/network/policies/allow-dns-and-apiserver.yaml` | Reusable DNS+API allow template |
| `gitops/data/networkpolicy/kustomization.yaml` (removed 2026-09-06 with the `data` namespace) | Pilot overlay for `data` namespace (the model every later namespace's overlay copies) — historical, no longer on disk |
| `tests/networkpolicy.bats` | Baseline clusterless YAML structural tests (per-namespace overlays get their own `tests/networkpolicy-<ns>.bats`) |
| `docs/dependency-tree.md` | The continuously-maintained enumeration of every namespace's NetworkPolicy posture — treat as current, this ADR as the pattern |

**Delivery mechanism added post-pilot (fan-out):**

| Path | Role |
|------|------|
| `gitops/platform/networkpolicy-appset.yaml` | `ApplicationSet` (list-generator) that plants the per-namespace overlay Application for every fanned-out namespace — the sole delivery mechanism today, not a standalone Application per namespace |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Policies land as ArgoCD `Application`s from git paths — consistent with GitOps-only; no `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Deny-by-default is the decoupled, explicit posture; no single catch-all rule is a SPOF. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Policies are only declared once the cluster's CNI actually enforces them — otherwise they'd be silent no-ops (fabricated safety). |
| [ADR-0012](adr-0012-istio-ambient-not-sidecar.md) | `NetworkPolicy` and Istio `AuthorizationPolicy` were complementary, not redundant, while Istio was in the lab (removed entirely, ADR-0012's own Status). |
| [ADR-0014](adr-0014-cilium-not-flannel-policy.md) | **Former prerequisite, now removed (2026-09-07, no replacement).** k3s's bundled Flannel + kube-router — ADR-0014's own originally-rejected option — enforces this ADR's policies now; see "Cilium's removal" above. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | Companion security ADR (host network controls vs pod security controls). |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-18 — Argo CD repo-server RCE exposure kept (audit #526)

**Trigger.** Security researchers disclosed (2026-07, ~18 months after
reporting it to the maintainers) an unpatched, un-CVE'd flaw in Argo CD's
`repo-server`: an unauthenticated internal gRPC service (`GenerateManifest`)
that anyone able to reach the port can abuse for arbitrary command execution
via Kustomize's Helm integration, leading to cluster takeover. No fix exists;
the researchers' own stated mitigation is restricting network access to
`repo-server` + Redis to Argo CD's own components — the upstream chart ships
these NetworkPolicies but leaves them disabled by default.

**Decision: keep the current posture — already mitigated.** Checked directly
against this lab's actual `gitops/argocd/networkpolicy/` overlay rather than
assuming: only `argocd-server` (TCP 8080) has a cross-namespace ingress allow
(from Envoy Gateway proxy pods, plus an Alloy metrics-scrape allow);
`repo-server` (:8081) and `argocd-cache`/Redis (:6379) have no ingress rule
reachable from outside the `argocd` namespace — the only rule touching them,
`allow-argocd-intra-namespace.yaml`'s bare `podSelector: {}`, is same-namespace
-only. Cross-checked every other namespace's overlay for an egress rule that
could reach those ports: the only two rules egressing to `argocd`
(`gitops/kargo/networkpolicy/allow-kargo-egress-argocd.yaml`,
`gitops/kargo-project/networkpolicy/allow-capstone-pipeline-egress-argocd.yaml`)
are both scoped to TCP 80 (the API server) only. Kubernetes NetworkPolicy
requires both source-egress and destination-ingress to allow a flow, so
`repo-server`/Redis are unreachable from outside `argocd` in this cluster
today — this lab already runs the researchers' own recommended mitigation, as
a side effect of this ADR's 2026-07-14 default-deny fan-out rather than a
deliberate response (the fan-out predates this disclosure).

**Residual exposure.** Intra-namespace only: any pod already running inside
`argocd` could still reach `repo-server` — the same accepted trust boundary
`allow-argocd-intra-namespace.yaml`'s own carve-out already documents (every
component there is part of one tightly-coupled control plane; see
[§Scope & exceptions](#scope--exceptions)).

**ADR-0004 caveat.** This is a static config review, not a live-cluster
penetration test — this remote clusterless session cannot confirm Cilium is
actually enforcing these policies as configured on a real cluster.

**Flip condition.** Revisit if Argo CD ships an official patch/CVE with a
different recommended mitigation, or if any future ROADMAP item adds a new
pod to the `argocd` namespace or a new cross-namespace egress rule targeting
ports 8081/6379.

---

### 2026-08-10 — `artifactory` namespace removed (decommissioned); `cert-manager`/`keda` added (were missing) — drift correction

**Trigger.** This ADR's §Scope & exceptions still listed `artifactory` as an
in-scope namespace (both the enumeration and the "On-demand namespaces" table
row) and carried a dedicated carve-out table row describing a live
`artifactory-oss-0` pod's `wait-for-db` NetworkPolicy fix — but Artifactory was
fully decommissioned 2026-07-29 (RFC #297 / ADR-0024, `auto/harbor-
artifactory-decommission`), the same date the carve-out row itself cites as
"found live." `find gitops -iname "*artifactory*"` returns zero results, the
`networkpolicy-appset.yaml` list-generator has no `artifactory-networkpolicy`
entry, and `tests/no-artifactory.bats` is a standing recurrence guard against
any of it coming back — but this ADR's own prose was never updated when the
decommission PR landed (ADR-0017's equivalent per-namespace table *was*
updated with a dated closing entry at the time; this ADR was the one left
behind). Separately, the same audit found `cert-manager` and `keda` — both
real, live, auto-synced namespaces with their own standalone `gitops/platform/
{cert-manager,keda}-networkpolicy.yaml` Applications (the same "standalone
Application, not the shared appset" pattern this ADR's own enumeration already
uses for `argo-rollouts`/`kargo`/`kyverno`/`trivy-system`/`velero`) — were
simply never added to the enumeration in the first place, a grooming gap
distinct from the Artifactory removal.

**Decision: correct the record.** Removed `artifactory` from the namespace
enumeration and the "On-demand namespaces" table row; deleted its now-stale
carve-out table row entirely (no closing entry needed beyond this log — the
namespace itself is gone, unlike ADR-0019's `argocd` Kyverno-carve-out
removal, which kept the namespace and only dropped one policy exclusion).
Added `cert-manager` and `keda` to the enumeration (now 28 namespaces,
verified directly against `gitops/platform/{cert-manager,keda}-networkpolicy
.yaml`'s `automated: {prune: true, ...}` syncPolicy — both genuinely live).

**Flip condition.** None pending — this is a closed record correction, not an
open question. Per this ADR's own §Scope & exceptions note ("This list drifts
as new components land — treat `docs/dependency-tree.md` as the live source
of truth and this ADR as the *pattern*, not the enumeration"), the
enumeration will drift again as new namespaces land; that's expected and not
itself a defect — only a claim about a *specific, no-longer-existing* pod
(like the artifactory row was) is the actionable bug class this entry closes.
