# ADR-0027 — First cloud backend: Oracle Cloud Always Free + k3s

**Decision.** The first cloud backend implementing the [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md)
contract is **Oracle Cloud Infrastructure's Always Free tier** (Ampere A1 ARM compute),
running **k3s** installed directly on the VM (no managed control-plane service). New
Terragrunt unit set: `infra/live/oracle/{cluster,argocd,gitlab}/`, backed by a new
`infra/modules/oracle-k3s-cluster` module.

**Why this backend, not a managed Kubernetes service.** [ADR-0025](adr-0025-free-oss-tiers-only.md)
requires that the lab run "entirely on a free/open-source tier... with zero spend." I
checked the three major managed-Kubernetes free tiers against that bar (current as of
2026-07-13):

| Option | Control plane | Compute (nodes) | Verdict |
|---|---|---|---|
| **Azure AKS** (Free tier) | $0/hr forever — no time limit, no credit mechanism | Not free: Azure's free VM hours are a 12-month trial offer, not permanent | Control plane clears the bar; compute does not — a lab spec that goes unusable after 12 months isn't "zero spend," it's a trial. |
| **GKE Autopilot** | $0 effectively — $74.40/mo billing-account credit exactly offsets the one-cluster $0.10/hr management fee | Not free: Autopilot bills per pod resource request; the credit only covers the cluster fee, not workload compute | Same problem — the credit mechanism covers the *management* fee, not the actual compute the lab's ~28 Applications would consume. |
| **Oracle Cloud Always Free (Ampere A1)** | N/A — no managed control plane; self-manage k3s | **Free forever**, no trial/credit mechanism, no time limit | Only option where *both* control plane and compute genuinely clear ADR-0025's bar indefinitely. |

Oracle reduced the Always Free Ampere A1 allocation in 2026 from 4 OCPU/24 GB to
**2 OCPU/12 GB** — smaller than the lab's current 12 GB Colima VM, so the always-on
stack (~7 GB) fits but the same "on-demand heavy components, never two full stacks"
discipline from [ADR-0003](adr-0003-decoupled-no-spof.md) applies here too, and possibly
more tightly. This is a real constraint, not a dealbreaker: it's still Always Free,
permanently, which is the property that actually matters for ADR-0025.

**Why self-managed k3s, not a third-party managed offering on OCI.** k3s is already the
lab's chosen engine (k3d wraps k3s in Docker for the localhost backend — ADR-0001's
day-0 bootstrap). Running k3s directly on the Oracle VM (instead of k3d, which needs
Docker-in-VM indirection for no benefit on a real host) reuses the exact same
distribution, minimizes new technology surface area, and keeps the "GitOps deploys
everything above the bootstrap seam identically" property from ADR-0026 trivially true —
`gitops/` never has to know whether it's talking to k3d or bare k3s.

**Contract compliance (ADR-0026 / `infra/live/README.md`).** The `oracle-k3s-cluster`
module must produce the same three outputs as `k3d-cluster`:
- `cluster_name` — the OCI instance/cluster identifier.
- `kube_context` — after `terraform apply`, this context must resolve in the local
  kubeconfig. Mechanically: the module provisions the instance, installs k3s via
  cloud-init (`curl -sfL https://get.k3s.io | sh -`), then a `local-exec` provisioner
  `scp`s `/etc/rancher/k3s/k3s.yaml` from the instance and merges it into
  `~/.kube/config` under a distinct context name (renaming the default `default`
  context k3s writes, to avoid colliding with the localhost backend's `k3d-k8s-lab`
  context if both are ever configured at once).
- `api_endpoint` — the VM's public IP on port 6443.

**Terraform state.** Per [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md)'s
reasoning (a cloud backend may use its own state approach rather than inheriting the
localhost backend's off-cluster Garage), the `oracle` backend's Terragrunt units use a
**second off-cluster Garage-compatible state store, on the same free Oracle VM** —
consistent with "no rented instances beyond what's already Always Free," rather than
introducing OCI Object Storage (a second free-tier service with its own separate quota
to track) purely for state.

**What this ADR does NOT do.** It does not implement the module — that is 🟢 executor
work, tracked in ROADMAP.md, split per `infra/live/README.md`'s three-unit structure.
It does not change anything about the localhost backend, which remains the default.

**Status.** Adopted 2026-07-13, per RFC (see the linked GitHub issue). First
cloud-backend implementation of [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md).
