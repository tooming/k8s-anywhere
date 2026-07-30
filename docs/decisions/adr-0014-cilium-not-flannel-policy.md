# ADR-0014 — Cilium CNI, not k3s's bundled Flannel + NetworkPolicy controller

**Status.** Adopted. Decision taken in RFC #82 (the default-deny `NetworkPolicy`
prerequisite). Per WAYS-OF-WORKING.md §2 the architect's RFC is binding; this ADR
captures the prerequisite swap that #82's Decision step 1 demanded. The Cilium
chart manifests are a follow-on item (the planner will groom from RFC #82's
acceptance criteria).

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
   `cilium/cilium` ≥ v1.16), `make cilium-up` / `make cilium-down`, bats
   tests, **and flips the default** to `true` in
   `infra/live/local/cluster/terragrunt.hcl`. A pre-merge note in DR.md will
   explain that the next `make up` requires `make cilium-up` immediately
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
| `docs/DR.md` | "After `make up`, run `make cilium-up` before any workload" note. |
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
