# infra/live/ — backend modules (ADR-0026)

Each top-level directory here is a **backend**: a concrete place the lab's cluster can
run. `local/` (k3d, on the operator's own machine) is the free, zero-external-dependency
**default** every `make up` path assumes. `oracle/` (Oracle Cloud Always Free + k3s,
ADR-0027) is the first opt-in cloud backend. Per
[ADR-0026](../../docs/decisions/adr-0026-cloud-agnostic-infrastructure.md), backends
sit alongside each other as siblings — `infra/live/<backend>/` — never as a fork of
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

| Backend | Status | Notes |
|---|---|---|
| `local/` | Built, default | k3d on the operator's own machine — zero external cost or account. |
| `oracle/` | Built, **partially verified against a real account (2026-07-15)** | [ADR-0027](../../docs/decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) / [RFC #377](https://github.com/tooming/k8s-anywhere/issues/377) / [issue #406](https://github.com/tooming/k8s-anywhere/issues/406). Oracle Cloud Always Free (Ampere A1) running k3s. Verified end-to-end against a real tenancy, from both a local session and [`.github/workflows/oracle-cluster-apply.yml`](../../.github/workflows/oracle-cluster-apply.yml) (manual-dispatch only, no `destroy`): `scripts/tfstate-oracle-bootstrap.sh` (off-cluster Garage tfstate backend), `terragrunt init` against that backend's real S3 API, and the `cluster/` unit's VCN/subnet/security-list/internet-gateway layer all apply cleanly. Found and fixed four real bugs only a live run could surface (missing `docker` group grant in the tfstate cloud-init, a VCN `dns_label` over OCI's 15-char limit, `vm-standard-e2-1-micro-count` quota being AD-specific rather than uniform, and the GitHub Actions workflow's Terraform pin being too old for the s3 backend's `use_path_style`/`endpoints` args). **Not yet verified**: the k3s compute instance itself — Oracle's Ampere A1 Always Free host capacity has been exhausted across all 3 ADs in `eu-frankfurt-1` on every attempt so far (a transient, external constraint, confirmed via `500 Out of host capacity` on every AD, both locally and from the Actions runner), so `docs/done/` and this row will be updated again once a `terragrunt apply` completes an actual instance launch. [`.github/workflows/oracle-cluster-apply-retry.yml`](../../.github/workflows/oracle-cluster-apply-retry.yml) already retries the launch **automatically, hourly** (`cron: "17 * * * *"`, added PR #422) — it treats `Out of host capacity` as an expected, non-alerting outcome and only fails loudly on any other error, so no executor action is needed to keep retrying; a manual `gh workflow run` against `oracle-cluster-apply.yml` would just be redundant with this. |

Choosing and building a *further* cloud backend (a second provider) is a new infra
dependency, so it needs its own RFC/ADR first — the architect's decision, per
[WAYS-OF-WORKING.md](../../docs/WAYS-OF-WORKING.md) — following the same pattern RFC #377
used for `oracle/`.
