# infra/live/ — backend modules (ADR-0026)

Each top-level directory here is a **backend**: a concrete place the lab's cluster can
run. `local/` (k3d, on the operator's own machine) is the only backend today and stays
the free, zero-external-dependency default every `make up` path assumes. Per
[ADR-0026](../../docs/decisions/adr-0026-cloud-agnostic-infrastructure.md), additional
backends (a managed cloud Kubernetes service, a self-managed cluster, etc.) are meant to
sit alongside it as opt-in siblings — `infra/live/<backend>/` — never as a fork of
`local/` or of anything in `gitops/`.

## The contract a backend must satisfy

Every backend directory has exactly three Terragrunt units, mirroring `local/`:

| Unit | Terraform source | Responsibility |
|---|---|---|
| `cluster/` | `infra/modules/<backend>-cluster` (backend-specific) | Stand up the Kubernetes cluster itself. |
| `argocd/` | `infra/modules/argocd` (shared, unchanged) | Install ArgoCD into whatever cluster `cluster/` produced. |
| `gitlab/` | `infra/modules/gitlab-config` (shared, unchanged) | Configure the GitLab source ArgoCD reads from. |

**Only `cluster/` is backend-specific.** `argocd/` and `gitlab/` never change per backend
— they depend on `cluster/`'s outputs and are otherwise identical to `local/`'s units
verbatim. This works because of a narrow, already-in-place output contract:

- `cluster_name` (string) — the cluster's name.
- `kube_context` (string) — a kubectl context name that, **after `terraform apply`
  completes, resolves in the local kubeconfig** (`~/.kube/config`, or wherever
  `KUBECONFIG` points) to a working connection to the cluster. `argocd/` and `gitlab/`
  both generate their `helm`/`kubernetes`/`gitlab` providers from exactly this — see
  their `generate "provider"` blocks, which read `dependency.cluster.outputs.kube_context`
  and `pathexpand("~/.kube/config")` unconditionally.
- `api_endpoint` (string) — the Kubernetes API server URL. Informational; not currently
  consumed by `argocd/`/`gitlab/`, but part of the contract so tooling built against one
  backend keeps working against another.

A new backend therefore only needs to:
1. Write `infra/modules/<backend>-cluster/` — a Terraform module that creates a cluster
   and leaves a working kubectl context locally (for a managed cloud service this is
   normally whatever `aws eks update-kubeconfig` / `gcloud container clusters
   get-credentials` / equivalent equivalent-in-Terraform step the provider needs — bake
   it into the module via a `null_resource`/`local-exec`, or an equivalent provider
   resource, so `terraform apply` alone is sufficient, matching how `k3d-cluster`
   requires no extra manual step).
2. Add `infra/live/<backend>/{cluster,argocd,gitlab}/terragrunt.hcl`, copying `local/`'s
   `argocd/`/`gitlab/` units unchanged and pointing `cluster/`'s `source` at the new
   module.
3. Add a `root.hcl` (or extend the shared one) for the backend's Terraform state
   backend — `local/`'s off-cluster Garage instance (ADR-0007) is itself
   backend-specific bootstrap substrate, not something every backend must reuse; a cloud
   backend may use that cloud's native state backend instead, documented in its own ADR
   when it's built.

## What stays out of scope for a backend module

Per [ADR-0001](../../docs/decisions/adr-0001-gitops-over-terraform-helm.md), a backend
module bootstraps the cluster **only** — day-1+ workloads are ArgoCD `Application`s in
`gitops/`, identical across every backend. Per
[ADR-0025](../../docs/decisions/adr-0025-free-oss-tiers-only.md), the *module code*
must not require a paid SaaS dependency to function; the infrastructure a cloud backend
provisions (compute, managed control plane, etc.) is the operator's own cost, not a lab
requirement — `local/` remains the path with zero external cost or account.

## Status

`local/` is the only backend implemented today. Choosing and building the first cloud
backend is a 🟡 Yellow-tier decision (new infra dependency — see
[WAYS-OF-WORKING.md §2](../../docs/WAYS-OF-WORKING.md)) that needs its own RFC/ADR before
implementation, since it picks a specific provider and (per ADR-0007's reasoning) a
specific Terraform-state approach — see ROADMAP.md for the tracked follow-up item.
