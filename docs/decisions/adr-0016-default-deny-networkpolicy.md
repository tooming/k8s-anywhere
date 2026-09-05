# ADR-0016 — Default-deny NetworkPolicy per namespace (Cilium-enforced)

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

1. A policy-capable CNI — covered by **ADR-0014** (Cilium, swapping out
   k3s-default Flannel which does not enforce `NetworkPolicy`).
2. The policy fan-out itself: two baseline policies per namespace (deny-all +
   allow-DNS-and-apiserver) plus per-workload explicit-allow policies.

Without ADR-0014's Cilium prerequisite every `NetworkPolicy` object lands
declaratively but is silently non-functional — exactly the "fabricated content"
anti-pattern ADR-0004 forbids. This ADR therefore depends on ADR-0014 being
active (i.e. the cluster has been brought up with `disable_default_cni = true`
and `make cilium-up` has run).

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

Named for the flow they permit (e.g. `allow-grafana-to-mimir`,
`allow-eso-from-vault`). One YAML file per flow, co-located with the workload
it serves (e.g. `gitops/observability/networkpolicy/allow-grafana-to-mimir.yaml`).
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
| **Pilot** (this ADR) | `data` namespace | RabbitMQ + Redis are self-contained, the existing "Lab — RabbitMQ" / "Lab — Redis" dashboards and `data-demo` load generator give immediate signal if a policy is wrong. |
| **Fan-out** (planner-groomed items, one namespace per executor run) | Every remaining always-on namespace, delivered two ways: (a) the `networkpolicy` `ApplicationSet` (`gitops/platform/networkpolicy-appset.yaml`, list-generator, wave 3, generated Applications at wave 4) — the majority of namespaces; (b) a handful of standalone `<ns>-networkpolicy` Applications for namespaces whose overlay predates the appset or that carry component-specific wiring (`kyverno`, `trivy-system`, `argo-rollouts`, `envoy-gateway-system`, `velero`, `kargo`, `kargo-project`) | Sequential, one namespace per executor run so failures are isolated; the appset consolidated most of the standalone Applications this pattern originally produced into one list, per RFC #82's spirit without one YAML file per namespace in `gitops/platform/`. |
| **On-demand namespaces** | `harbor`, `istio-system`, `longhorn-system` | **Auto-synced ahead of the on-demand bring-up**, not "with" it as originally planned — the namespace's default-deny floor (via the appset) is in place *before* `make <name>-up` ever admits a pod, so there's no policy race on first bring-up. Same `automated: {prune, selfHeal}` policy as every other appset entry. |
| **Out of scope** | `kube-system` | Contains kube-dns, metrics-server, and the kubelet's SA issuer; flows are complex and a policy mistake here takes the cluster down. Unchanged since this ADR was adopted. |

---

## Why Cilium (from ADR-0014)

The detailed CNI-choice rationale lives in ADR-0014. Summary:

- k3s's bundled Flannel does not enforce `NetworkPolicy` — any policy placed
  before the CNI swap is silently non-functional.
- Cilium (CNCF graduated 2023) is the eBPF-native CNI that new clusters reach
  for in 2026. It enforces standard `NetworkPolicy` and provides the richer
  `CiliumNetworkPolicy` for future L7 rules.
- Calico was considered — still excellent, rejected because Cilium fits the
  lab's eBPF learning angle better and `kubeProxyReplacement` removes a layer.

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

**Namespaces in scope — fan-out complete (2026-07-14).** As of a 2026-08-10 drift
correction (see Re-evaluation log), 28 namespaces carry the two-policy floor:
`ack-system`, `argo-rollouts`, `argocd`, `capstone`, `capstone-pipeline`,
`cert-manager`, `data`, `envoy-gateway-system`, `external-secrets`, `harbor`,
`istio-system`, `kargo`, `keda`, `kro`, `kyverno`, `lab-demo`, `lab-gateway`,
`longhorn-system`, `moto`, `node-exporter`, `observability`, `storage`, `tidb`, `tidb-admin`,
`trivy-system`, `vault`, `velero`. This list drifts as new components land — treat
[docs/dependency-tree.md](../dependency-tree.md) as the live source of truth and this
ADR as the *pattern*, not the enumeration.

**Carve-outs / special handling:**

| Namespace | Treatment | Reason |
|-----------|-----------|--------|
| `kube-system` | out of scope | DNS, metrics-server, API issuer — a mistake here brings the cluster down. Separate RFC. |
| `istio-system`, `longhorn-system`, `harbor` (all on-demand) | policy auto-synced ahead of the component's own on-demand bring-up | The default-deny floor is in place before `make <name>-up` admits any pod — no policy race on first bring-up. Originally planned as "lands with the bring-up PR"; the appset pattern made pre-provisioning both possible and simpler. |
| `observability` | single broad `podSelector: {}` intra-namespace allow (`gitops/observability/networkpolicy/allow-intra-namespace.yaml`, `NetworkPolicy allow-observability-intra-namespace`) instead of one explicit per-flow policy per edge | Formalized 2026-07-15 (found via ROADMAP rule #9's coverage/hardening sweep — the manifest predates this row and was running as an undocumented deviation from "no catch-all 'allow same namespace'" above). The LGTMP stack has many legitimate, purpose-built intra-namespace flows (Alloy → Mimir/Loki/Pyroscope; Alloy ← KSM/LGTMP self-scrapes; Grafana → Mimir/Loki/Tempo/Pyroscope datasource reads; Pyroscope ↔ co-located pprof scrape targets) — every pod in the namespace is part of the same single-tenant observability pipeline, unlike namespaces mixing independent workloads. The cross-namespace boundary (the actual security perimeter ADR-0016 protects) stays fully explicit via the other per-namespace overlays; this carve-out only widens intra-namespace reachability within one already-cohesive, single-purpose component. **Flip condition:** if a future namespace-scoped threat model requires intra-namespace segmentation (e.g. a compromised low-privilege pod in `observability` should not reach Mimir's write path), replace this with explicit per-flow policies per the ADR's general pattern. |
| `argocd`, `harbor`, `istio-system`, `longhorn-system`, `tidb` | same single broad `podSelector: {}` intra-namespace allow pattern as `observability` above (`allow-{argocd,harbor,istio,longhorn,tidb}-intra-namespace.yaml` respectively) | Formalized 2026-07-15 alongside the `observability` row above — the same coverage sweep that found `observability`'s undocumented deviation found this is actually the **general, already-consistent convention** across every multi-component namespace, not a one-off: each of these namespaces hosts a single purpose-built, tightly-coupled multi-component stack (ArgoCD's controller/server/repo-server/cache; Harbor's core/registry/jobservice/portal/database; the Istio ambient control plane; Longhorn's manager/engine/CSI plugin; the TiDB cluster's PD/TiKV/TiDB/tidb-demo) with no independent tenants mixed in, and each manifest's own header comment already carried this exact rationale before this row existed. Same flip condition as `observability`: replace with explicit per-flow policies if a future threat model requires intra-namespace segmentation within one of these namespaces. **General principle (to prevent this same gap recurring for a future namespace):** a namespace may use one broad intra-namespace allow instead of per-flow policies when every pod in it is part of the same single-tenant, purpose-built multi-component stack — the cross-namespace boundary is the security perimeter ADR-0016 protects; the intra-namespace convenience allow never widens *that* boundary. |

**Istio ambient, once up:** `NetworkPolicy` (CNI layer) and Istio
`AuthorizationPolicy` (L7/identity layer) are complementary per CNCF guidance
— both stay in place.

---

## Files this work touches

**Pattern (unchanged since the pilot):**

| Path | Role |
|------|------|
| `docs/decisions/adr-0016-default-deny-networkpolicy.md` | This ADR |
| `gitops/network/policies/default-deny.yaml` | Reusable deny-all template |
| `gitops/network/policies/allow-dns-and-apiserver.yaml` | Reusable DNS+API allow template |
| `gitops/data/networkpolicy/kustomization.yaml` | Pilot overlay for `data` namespace (the model every later namespace's overlay copies) |
| `gitops/data/networkpolicy/allow-rabbitmq-ingress.yaml` | Allow ingress to RabbitMQ (5672, 15692) |
| `gitops/data/networkpolicy/allow-valkey-ingress.yaml` | Allow ingress to Valkey (6379, 9121) |
| `gitops/data/networkpolicy/allow-data-demo-egress.yaml` | Allow data-demo → RabbitMQ + Redis |
| `tests/networkpolicy.bats` | Baseline clusterless YAML structural tests (per-namespace overlays get their own `tests/networkpolicy-<ns>.bats`) |
| `docs/dependency-tree.md` | The continuously-maintained enumeration of every namespace's NetworkPolicy posture — treat as current, this ADR as the pattern |

**Delivery mechanism added post-pilot (fan-out):**

| Path | Role |
|------|------|
| `gitops/platform/networkpolicy-appset.yaml` | `ApplicationSet` (list-generator) that plants the per-namespace overlay Application for most fanned-out namespaces — the primary delivery mechanism today, not a standalone Application per namespace |
| `gitops/platform/{kyverno,trivy-system,argo-rollouts,envoy-gateway-system,velero,kargo,kargo-project}-networkpolicy.yaml` | Standalone `<ns>-networkpolicy` Applications for namespaces whose overlay predates the appset or carries component-specific wiring |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Policies land as ArgoCD `Application`s from git paths — consistent with GitOps-only; no `kubectl apply`. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Deny-by-default is the decoupled, explicit posture; no single catch-all rule is a SPOF. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | Policies are only declared after ADR-0014's Cilium is active — otherwise they'd be silent no-ops (fabricated safety). |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | CNI swap leaves Envoy Gateway intact; `NetworkPolicy` operates below the ingress L7 layer. |
| [ADR-0012](adr-0012-istio-ambient-not-sidecar.md) | `NetworkPolicy` and Istio `AuthorizationPolicy` are complementary, not redundant. |
| [ADR-0014](adr-0014-cilium-not-flannel-policy.md) | **Prerequisite.** Cilium must be active before any policy is functional. |
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
