# ADR-0026 — Cloud-agnostic infrastructure target (localhost stays the free default)

**Decision.** The lab's infrastructure bootstrap (Terraform/Terragrunt — ADR-0001) is
generalized into **pluggable backend modules** selected at apply time, so the identical
GitOps state in `gitops/` can deploy to:

1. **Localhost** via k3d/Colima — the **default, free, zero-external-dependency**
   backend every quick-start path (`make up`) assumes, unchanged from today.
2. **Any CNCF-conformant cloud Kubernetes service** (EKS, GKE, AKS, or a
   self-managed cluster) — an opt-in alternate the operator chooses explicitly.

No layer above the Terraform bootstrap seam may encode a backend-specific assumption:
ArgoCD `Application`s, Kustomize overlays, and Helm values stay identical regardless of
where the cluster runs. Portability is a property of the *architecture*, not a
per-backend fork of the GitOps tree.

**Why.** The lab's original strategy statement ("Localhost over cloud... no rented
instances, no cloud accounts") optimized for zero-cost reproducibility, which remains
essential — but it also means the lab can only be *run*, not just *read about*, by
someone with a 16 GB Mac. Generalizing the bootstrap seam keeps that zero-cost path as
the default while letting the same platform prove itself on real cloud infrastructure —
which is itself a teaching goal: a design that only works on one operator's laptop
hasn't actually demonstrated portability. Maintainer decision, 2026-07-13.

**Scope — what this does and does not change:**

| Existing ADR | Effect |
|---|---|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Reinforced, not weakened — pluggability lives entirely inside the Terraform-only bootstrap seam; GitOps still deploys every workload. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | **Unchanged**, still binding — but scoped explicitly to the localhost backend. A cloud backend has independent failure domains available to it and gets its own HA/recoverability ADR once built; it does not inherit ADR-0005's "single host, no true HA" reasoning by default. |
| [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) | **Unchanged**, still binding for the localhost backend's Terraform state. A cloud backend may use that cloud's native state backend (e.g. a managed object store with locking) — a separate, future ADR when that module lands, not a retrofit of this one. |
| [ADR-0025](adr-0025-free-oss-tiers-only.md) | **Unchanged and still binds the *software***: every dependency the lab installs must stay free/OSS regardless of backend. It does **not** extend to infrastructure rental — choosing a cloud backend is the operator's own cost decision, outside the lab's control, and never a requirement of the default path. |

**How this binds.** Future `infra/` work must not hardcode localhost/Colima/k3d
assumptions outside of the localhost backend module. A new cloud backend module is
itself 🟡 Yellow-tier work (`infra/` bootstrap change — see
[WAYS-OF-WORKING.md §2](../WAYS-OF-WORKING.md#2-autonomy-tiers-what-an-agent-may-do-unsupervised))
and, if it introduces a new binding technical choice (a specific cloud provider's
Terraform module, its state backend, its ingress/LB equivalent to the front door),
that choice gets its own ADR rather than silently expanding this one.

**Status.** Adopted 2026-07-13. Supersedes the CHARTER.md Strategy statement
"Localhost over cloud" (see the current [CHARTER.md](../../CHARTER.md) Strategy
section for the replacement). This ADR is a target-architecture decision — the
pluggable cloud backend module itself is not yet built; it is tracked as ROADMAP work
the planner/architect derive from the CHARTER per the usual cadence.
