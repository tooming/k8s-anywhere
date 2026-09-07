# ADR-0014 — Cilium CNI, not k3s's bundled Flannel + NetworkPolicy controller

**Status.** Removed 2026-09-07, no replacement — superseded by using k3s's bundled
Flannel + kube-router instead (maintainer decision — component dropped from the lab
entirely; cluster reverts to k3s's bundled Flannel CNI + kube-router NetworkPolicy
controller, this ADR's own originally-rejected option). The
`gitops/platform/cilium.yaml` Application, every `CiliumNetworkPolicy` custom resource
under `gitops/` (including the shared `allow-dns-and-apiserver.yaml` and
`zz-dns-clusterip-bridge.yaml` baseline templates and the per-component
`allow-*-webhook-from-apiserver.yaml`/`allow-argocd-service-frontends.yaml` policies),
`scripts/cilium-apiserver-drift-check.sh`, the `cilium-up`/`cilium-down`/
`cilium-drift-check` Makefile targets, and `tests/cilium.bats` were deleted in this or a
paired change. `infra/modules/k3d-cluster`'s `disable_default_cni` flip (and the
`k3d-config.yaml.tftpl` `--flannel-backend=none`/`--disable-network-policy` args it
renders) is reverted to k3s's defaults as a separate, coordinated infra change — see
that module and `infra/live/local/cluster/terragrunt.hcl` for the live flip. The
`CiliumNetworkPolicy` resources this ADR's default-deny fan-out depended on have no
in-repo plain-`NetworkPolicy` replacement yet; the namespace `networkpolicy/
kustomization.yaml` overlays that referenced the deleted files, `tests/networkpolicy*.bats`,
and `docs/decisions/adr-0016-default-deny-networkpolicy.md` still need a follow-up pass
to either restore equivalent allow-rules as plain `NetworkPolicy` (viable now that
kube-router's iptables-based enforcement, unlike Cilium's kube-proxy-free socket-LB
datapath, does not silently miss ClusterIP-fronted egress) or drop the rules they encoded.
The decision record below is kept for history (why Cilium was adopted, what it
demonstrated) but no longer describes anything live in the repo — do not treat any
manifest path or Makefile target named below as still existing.

~~**Status.** Adopted. Decision taken in RFC #82 (the default-deny `NetworkPolicy`
prerequisite). Per WAYS-OF-WORKING.md §2 the architect's RFC is binding; this ADR
captures the prerequisite swap that #82's Decision step 1 demanded. The Cilium
chart manifests are a follow-on item (the planner will groom from RFC #82's
acceptance criteria).~~

---

## Context

[RFC #82](https://github.com/tooming/k8s-lab/issues/82) calls for a
deny-by-default + allow-by-exception network-segmentation model expressed in the
standard `networking.k8s.io/v1` `NetworkPolicy` API, with two baseline policies
per namespace and per-workload `allow-<flow>` policies on top.

That model only works if the cluster's CNI actually enforces `NetworkPolicy`.
k3s ships **Flannel** as its default CNI; Flannel is layer-2 fabric only and
does **not** enforce `NetworkPolicy`. k3s used to bundle a separate
`kube-router`-style policy controller, but it's neither feature-complete nor
the way clusters at production scale do this in 2026. Without a policy-capable
CNI every `NetworkPolicy` object would land declaratively but silently
non-functional — exactly the "fabricated content" anti-pattern ADR-0004
forbids.

So before the executor can implement any policy work from RFC #82, the
cluster's data plane has to be swapped to a CNI that enforces policy.

---

## Decision

Swap the lab's CNI from k3s-default **Flannel** to **Cilium**.

Two halves:

1. **Bootstrap-time disable of k3s's bundled CNI + policy controller.** Pass
   `--flannel-backend=none --disable-network-policy` to the k3s server args in
   the k3d config template (`infra/modules/k3d-cluster/k3d-config.yaml.tftpl`).
   Gated on a new module variable `disable_default_cni` (default **`false`**,
   so existing clusters keep working until the operator explicitly opts in).

2. **Cilium installed as a non-auto-synced ArgoCD `Application`** (separate
   follow-on PR — out of scope here, in scope for the planner's grooming of
   RFC #82's acceptance criteria). Chart `cilium/cilium` ≥ **v1.16** from
   `https://helm.cilium.io`, in namespace `kube-system`, with
   `kubeProxyReplacement: true` and `hubble.enabled: false` to stay inside the
   12 GB budget (Hubble adds ~250–400 MB; the learning value isn't worth the
   spend for v1 of the network-segmentation work).

The opt-in default keeps this ADR + infra/ diff safe to merge **before** the
Cilium chart lands: clusters built with the default settings continue to use
Flannel and behave exactly as before. The switch is atomic with the Cilium
chart bring-up: a future PR sets `disable_default_cni = true` in
`infra/live/local/cluster/terragrunt.hcl` AND lands
`gitops/platform/cilium.yaml` in the same change.

---

## Why Cilium

| Criterion | Cilium | Alternatives considered |
|-----------|--------|--------------------------|
| **Policy enforcement** | First-class `NetworkPolicy`; richer `CiliumNetworkPolicy` available if L7 rules are ever needed | Calico also fully enforces — see below |
| **Data plane** | eBPF in-kernel, no per-packet iptables traversal | Calico defaults to iptables (it has an eBPF mode behind a flag) |
| **kube-proxy** | Can replace kube-proxy entirely (`kubeProxyReplacement: true`) — one less moving part | Calico does not natively replace kube-proxy |
| **CNCF status** | Graduated 2023 — the eBPF-native CNI new clusters reach for in 2026 | Calico is incubating, still excellent; kube-router is a much smaller community |
| **Learning surface** | eBPF observability is a deliberate learning objective for the lab; Hubble (deferred) is the canonical "look inside the network plane" tool | Calico is more iptables-flavored; less novel for the lab's learning angle |
| **k3s/k3d documentation** | First-party guide for k3s/k3d — the swap is well-trodden | Calico on k3s is documented but less explicitly |

**Rejected alternatives:**

- **Calico** — feature-comparable policy enforcement, still excellent, more mature in some ops shops. Rejected because Cilium fits the lab's eBPF learning angle better and because `kubeProxyReplacement` lets us remove a layer. Calico would be the obvious choice if a user were already running Calico in production and wanted parity.
- **kube-router** — lightweight, but a much smaller community; sidesteps the eBPF learning objective entirely.
- **Flannel + a separate policy controller** (e.g. kube-router in policy-only mode) — *two* CNI components instead of one; rejected because operating two control planes is strictly worse than one.

---

## Why this is opt-in (`disable_default_cni = false` by default)

The lab is rebuilt with `make up` from code (ADR-0005). If we flipped the
default to `true` in this ADR, every `make up` would produce a cluster with
no CNI installed — pods stuck in `ContainerCreating`, the lab broken — until
the Cilium chart Application is also wired in.

Two-step bring-up:

1. **This PR (ADR-0014 + variable + template logic).** Default `false`.
   Existing clusters and any new `make up` keep using Flannel. The ADR
   records the decision; the infra/ machinery is in place but inert.
2. **Follow-on PR (planner-groomed from RFC #82).** Lands
   `gitops/platform/cilium.yaml` (non-auto-synced ArgoCD `Application` from
   `cilium/cilium` ≥ v1.16), make cilium-up / make cilium-down, bats
   tests, **and flips the default** to `true` in
   `infra/live/local/cluster/terragrunt.hcl`. A pre-merge note in DR.md will
   explain that the next `make up` requires make cilium-up immediately
   after.

This staging is the recreate-from-code property (ADR-0005) at work: a single
PR cannot half-break the cluster.

---

## 12 GB budget

Cilium footprint estimate for the lab (single-node k3d):

| Component | Approximate footprint |
|-----------|-----------------------|
| `cilium-agent` DaemonSet | ~250 MB |
| `cilium-operator` Deployment | ~70 MB |
| **Total (Hubble disabled)** | **~320 MB** |
| Hubble (deferred — not in this lane) | +250–400 MB |

This is the *replacement* footprint for Flannel (~50 MB) + the bundled policy
controller (~30 MB), so the net increase is ~240 MB. The always-on stack at
~7 GB + this ~240 MB stays well inside 12 GB.

Cilium is always-on (it IS the network data plane — it can't be "on-demand")
but the manifest is non-auto-synced for the staging reason above. Once the
follow-on PR flips the default and ships the chart, Cilium becomes part of
the always-on auto-synced set in `gitops/bootstrap/root-app.yaml`.

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Cilium is deployed as an ArgoCD `Application` from the official Helm chart in the follow-on PR. `helm install` is never run directly. The `infra/` template change here is the day-0 bootstrap seam, which ADR-0001 explicitly allows. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Cilium runs as a DaemonSet on every node; the operator is a single replica (acceptable per ADR-0005). |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-host lab: one Cilium operator replica, one node. Production runs ≥ 3 operator replicas. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Cilium is the L3/L4 CNI; Envoy Gateway is the L7 north-south ingress. They operate at different layers and are complementary. Cilium does NOT replace Envoy Gateway. |
| [ADR-0012](adr-0012-istio-ambient-not-sidecar.md) | Istio ambient's ztunnel runs on top of the CNI's pod networking; Cilium is a documented, supported substrate for Istio ambient. `NetworkPolicy` (CNI layer) and Istio `AuthorizationPolicy` (mesh layer) are complementary controls per CNCF guidance, not redundant. |

No existing ADR is contradicted; this is a new decision in a domain (CNI choice) the prior ADRs did not cover.

---

## Files this PR touches

| Path | Role |
|------|------|
| `docs/decisions/adr-0014-cilium-not-flannel-policy.md` | This ADR. |
| `infra/modules/k3d-cluster/variables.tf` | New `disable_default_cni` variable (default `false`). |
| `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` | Conditional `--flannel-backend=none --disable-network-policy` extraArgs. |
| `infra/modules/k3d-cluster/main.tf` | Pass the new variable into `templatefile`. |

## Files the follow-on PR will touch

| Path | Role |
|------|------|
| `gitops/platform/cilium.yaml` | Non-auto-synced ArgoCD `Application`, chart `cilium/cilium` ≥ v1.16, namespace `kube-system`; inline `valuesObject` sets `kubeProxyReplacement: true`, `hubble.enabled: false`. |
| `Makefile` | `cilium-up` / `cilium-down` targets. |
| `infra/live/local/cluster/terragrunt.hcl` | Flip `disable_default_cni = true`. |
| `docs/DR.md` | "After `make up`, run make cilium-up before any workload" note. |
| `tests/cilium.bats` | Application has no `automated:` block; default-deny baseline policies render. |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-28 — CVE-2026-33726 kept, pin already past the fix floor (audit #772)

**Trigger.** Routine CVE sweep found CVE-2026-33726 (Ingress NetworkPolicy
bypass for pod→L7-Service traffic with a local backend, when Per-Endpoint
Routing is enabled and BPF Host Routing is disabled), fixed in
`1.17.14`/`1.18.8`/`1.19.2`.

**Decision: Keep.** This lab's pin (`gitops/platform/cilium.yaml`'s
`targetRevision: 1.17.18`) is already past the `1.17.14` fix floor on the same
minor line — no bump needed. **Flip condition:** a CVE disclosed against
`1.17.18` specifically, or the `1.17.x` line reaching end-of-support.

### 2026-07-30 — 1.17.x reached end-of-support, converted to RFC (audit #916)

**Trigger.** Cilium `v1.20.0` was published 2026-07-29 (confirmed:
`github.com/cilium/cilium/releases.atom`). Cilium's `SECURITY.md` support
table (fetched directly, not training knowledge — ADR-0004) now marks every
version `< 1.18.0` as unsupported — this is exactly the flip condition
recorded in the 2026-07-28 entry above ("the `1.17.x` line reaching
end-of-support").

**Decision: Convert.** The pin should move off the unsupported line, but
Cilium's own upgrade path is sequential minor-by-minor — a live-cluster jump
straight from `1.17.18` to `1.20.0` is not a supported upgrade path, and this
remote clusterless session cannot verify pod networking survives any Cilium
version change on the live cluster (ADR-0004). Turned into
[RFC #917](https://github.com/tooming/k8s-anywhere/issues/917): bump to
`1.18.12` (latest `1.18.x` patch, confirmed via `git ls-remote --tags
https://github.com/cilium/cilium.git`) — one minor-line step, not the full
jump to `1.20.0`. **Flip condition for the next step:** once `1.18.12` lands,
revisit when `1.18.x` itself reaches end-of-support, or a CVE lands against
`1.18.12` specifically.

### 2026-07-30 — RFC #917 bump landed: `1.17.18` → `1.18.12`

**Decision.** `gitops/platform/cilium.yaml`'s `targetRevision` bumped to
`1.18.12` per the Convert decision above. Re-verified directly at pickup time
(not just the RFC's cached read): the `1.18.12` chart's `values.yaml` still
contains every key this Application's `valuesObject` sets unchanged in shape
— `kubeProxyReplacement`, `prometheus.enabled`/`port`, `hubble.enabled`,
`operator.replicas`/`resources`, top-level `resources` (fetched directly from
`raw.githubusercontent.com/cilium/cilium/v1.18.12/install/kubernetes/cilium/values.yaml`
and diffed against the `v1.17.18` tag's copy — no schema change). **Flip
condition:** revisit when `1.18.x` itself reaches end-of-support (per
Cilium's `SECURITY.md` support table), or a CVE lands against `1.18.12`
specifically.

### 2026-08-19 — three High GHSAs audited (already past fix floor), patch bump `1.18.12` → `1.18.13`

**Trigger.** Routine security-advisory sweep found three new **High**-severity
GHSAs published 2026-08-12 against `github.com/cilium/cilium`:
- **GHSA-33qq-jq9c-6gcc** — mutual-authentication identity spoofing via
  cert-chain substitution, CVSS 7.6, affects `1.18.0`–`1.18.11`, patched
  `1.18.12`.
- **GHSA-xqhm-7xhv-6ppj** — SDS secret-sync name collision enabling
  cross-namespace L7 policy bypass, CVSS 7.3, affects `1.18.0`–`1.18.11`,
  patched `1.18.12`.
- **GHSA-vh48-r624-p8v7** — VLAN-interface ingress/L7 policy bypass, CVSS
  7.2, affects `1.18.0`–`1.18.8`, patched `1.18.9` (older finding, predates
  this lab's `1.18.12` pin).

**Decision: Keep pin, no CVE-driven bump needed.** This lab's pin (`1.18.12`)
already sat at or past every one of these three fix floors — none of them
actually affects the running pin. This is the same "pin already past the fix
floor" shape as the 2026-07-28 entry above, on a different CVE set.

**Separately, a routine patch-currency check found `v1.18.13`** (released
2026-08-18, the day before this audit) is now the newest `1.18.x` tag. Its
release notes cite a security-relevant dependency bump (gRPC → `v1.82.1`,
"to address security vulnerabilities") plus routine bugfixes (host-firewall
unknown-CT-protocol tolerance, netlink hang fix, CIDR refcount fix, IP-
allocation fix). Cilium's `SECURITY.md` support table still lists `1.18.x`
as supported.

**Decision: Convert (bump) to `1.18.13`.** Re-verified directly, same method
as the 2026-07-30 entry: a byte-level diff of the `v1.18.12` vs `v1.18.13`
chart `values.yaml`
(`raw.githubusercontent.com/cilium/cilium/v1.18.1{2,3}/install/kubernetes/cilium/values.yaml`)
shows only image tag/digest changes — zero new, removed, or restructured
keys, so this Application's `valuesObject` needs no changes.
`gitops/platform/cilium.yaml`'s `targetRevision` bumped `1.18.12` → `1.18.13`.

**ADR-0004 caveat:** this remote, clusterless session cannot verify pod
networking/policy enforcement survives this bump on the live cluster.
Rollback: revert `targetRevision` — ArgoCD self-heals; Cilium is a DaemonSet
so a revert re-rolls the same way the bump did.

**Flip condition (next re-evaluation).** Unchanged from above: revisit when
`1.18.x` itself reaches end-of-support, or a CVE lands against `1.18.13`
specifically.

### 2026-09-03 — Critical advisory GHSA-3fcv-jvfp-m4q9 found unaudited, confirmed not applicable

**Trigger.** Planner-fallback GHSA sweep (`executor.prompt.md` STEP 6b,
Now/next's three standing items still gated on unconfirmed
maintainer-confirmation issues #631/#633) enumerated
`github.com/cilium/cilium`'s published security advisories directly (not
just the "new since the last date-filtered search" query the 2026-08-19
entry above used) and found **GHSA-3fcv-jvfp-m4q9** ("Sensitive information
disclosure and cluster disruption via local Envoy admin socket access",
**Critical**, CVE-2026-49445, published 2026-06-01) — a Critical-severity
advisory that **predates** the 2026-08-19 entry above but was never recorded
in this ADR's Re-evaluation log. The 2026-08-19 entry's own trigger was
scoped to "three new High-severity GHSAs published 2026-08-12" — a narrower,
date-filtered search that structurally couldn't have surfaced an
already-published June advisory it wasn't looking for. Not a claim that the
2026-08-19 audit was wrong for its own stated scope, but a real gap this
cycle closes: a Critical advisory sat unrecorded for three months.

**Verified directly (not assumed, ADR-0004):** the advisory's own affected/
patched ranges are `<1.19.2`, `1.18.0`–`1.18.7` (patched `1.18.8`),
`<1.17.14` (patched `1.17.14`). This lab's pin (`1.18.13`) is past the
`1.18.x` fix floor (`1.18.8`) by five patches — not affected. The
vulnerability itself (an insufficiently-protected local Envoy admin socket,
exploitable by a local user on the same node) requires Cilium's L7
functionality to be enabled; independent of that, the pin is simply past the
fix regardless.

**Scope note.** This was a targeted check of one Critical advisory found via
a broader listing pass, not an exhaustive re-audit of every advisory across
Cilium's full multi-page advisory history (a spot-check of page 2's ten
Moderate/Low advisories found nothing above Moderate severity and nothing
suggesting a floor above `1.18.13`, but pages 3+ were not exhaustively
walked this cycle) — said plainly per ADR-0004 rather than overclaiming
completeness.

**Decision: Keep pin, no CVE-driven bump needed.** `1.18.13` already sits
past this advisory's fix floor.

**Flip condition (next re-evaluation).** Unchanged: revisit when `1.18.x`
itself reaches end-of-support, or a CVE lands against `1.18.13` specifically.
A future cycle wanting stronger assurance than this cycle's spot-check
should walk Cilium's full multi-page advisory list end-to-end rather than
re-doing this same partial pass.

### 2026-09-07 — Removed entirely, no replacement (host capacity + aggressive simplification)

**Trigger.** Not a CVE/currency sweep like the entries above — a maintainer-directed
scope narrowing this session, alongside removing Kyverno, Argo Rollouts, Velero,
Trivy Operator, Kargo, Harbor, Forgejo, GitLab, and capstone the same day.

**Why.** Two independent pressures converged: (1) **host capacity, found live with
hard evidence** — this issue's own long-running host-capacity-ceiling investigation
(docs/incident-log.md's 2026-09-06 rows) repeatedly traced symptoms that looked like
"the host is out of capacity" back to Cilium specifically — a stale `cilium-agent`
`KUBERNETES_SERVICE_HOST` after every `colima start` hung pod-sandbox creation
cluster-wide (recurred 2026-07-29 and 2026-09-06), and Cilium's kube-proxy-free
socket-LB datapath is real, non-trivial overhead this single-node M4 Mac / 12 GB
Colima VM lab pays on every packet regardless of whether that specific bug is live;
(2) the maintainer's explicit **"no replacement, aggressive simplification"** direction
this session (the same direction that removed Kyverno, Argo Rollouts, Velero, Trivy
Operator, Kargo, Harbor, Forgejo, GitLab, and capstone the same day) — Cilium's
specific benefits documented in this ADR's original Decision (eBPF datapath
performance, kube-proxy-free mode, Hubble observability, richer `CiliumNetworkPolicy`
semantics) were real but not worth their operational cost in a single-node homelab
that was actively destabilized by them.

**What replaces it.** Nothing dedicated — k3s's bundled Flannel CNI + kube-router
NetworkPolicy controller (this ADR's own originally-rejected option) is used instead,
enforcing this lab's default-deny posture (ADR-0016) as plain `networking.k8s.io/v1`
`NetworkPolicy` rather than `CiliumNetworkPolicy`. The enforcement point moved: under
kube-router's iptables-based `FORWARD`-chain enforcement, kube-proxy's ClusterIP DNAT
happens first (in `PREROUTING`), so NetworkPolicy sees already-DNAT'd traffic to real
pod IPs — the opposite order from Cilium's pre-DNAT, socket-LB-based enforcement,
which evaluated policy before a ClusterIP was ever resolved to a backend pod. See
[`gitops/network/policies/allow-dns-and-apiserver.yaml`](../../gitops/network/policies/allow-dns-and-apiserver.yaml)'s
header comment for the full technical detail — plain podSelector/namespaceSelector
rules against real destination pods now work correctly and need none of the
socket-LB/pre-DNAT ClusterIP-CIDR workarounds Cilium required.

**Decision: Removed, no replacement.** See Status above for the exact scope of what
was deleted.

**Flip condition.** None planned — re-adopting a dedicated CNI/policy engine would be
a new ADR weighing the same trade-off afresh (host capacity vs. eBPF-datapath/
observability benefits) against whatever this lab's shape is at that time, not a
revival of this decision as originally reasoned.
