# ADR-0007 — Off-cluster Garage as the Terraform-state backend

**Status.** Adopted. Shipped in commit `a07a1d2`; active in `infra/live/local/root.hcl`,
`infra/tfstate/`, `scripts/tfstate-bootstrap.sh`, `make tfstate-up`.

---

## Context

The lab's Terraform/Terragrunt units (cluster, ArgoCD, GitLab) need a state
backend. Three options were on the table:

1. **Local file** (`terraform.tfstate` on disk) — lost when the working directory
   changes, conflicts with the recreate-from-code discipline (ADR-0005), and makes
   parallel apply unsafe.
2. **In-cluster Garage** (the always-on S3 object store — see ADR-0002) — attractive
   because the engine is already there, but creates a hard bootstrap loop: in-cluster
   Garage **is created by** the Terraform apply that would need to read state from it.
   You cannot store the state of "create the cluster" inside the cluster you haven't
   created yet.
3. **Off-cluster Garage** — a **separate, second Garage instance** brought up before
   any `terragrunt apply` (step 2 of `make up`, ahead of `cluster-up`). Same engine as
   ADR-0002 (lightweight Rust S3, no cloud dependency), different container, different
   purpose, different port — it lives alongside GitLab and the front door as bootstrap
   substrate rather than an in-cluster workload.

---

## Decision

Run a **second, off-cluster Garage instance** (`infra/tfstate/`, container
`tfstate-garage`) as the sole Terraform state backend for all Terragrunt units. It
starts before any `terragrunt apply` and is never part of the in-cluster workload set.

**Why not in-cluster Garage (option 2)?** The dependency graph is
`tfstate-up → cluster-up → argocd → … → in-cluster Garage`. The in-cluster Garage
is the _output_ of the cluster Terraform; it cannot simultaneously be that
Terraform's state store. Using it would require a local-state bootstrap, a
separate migration step on first apply, and a fragile ordering constraint that
is hard to operationalise. The separate off-cluster instance keeps the causal
order clean: the state store is _always available_ when Terraform runs, with no
cluster-not-yet-exists edge case.

**Why not a hosted/cloud S3 bucket?** This is a fully offline, localhost lab.
No AWS account, no Backblaze, no GCS — the whole point is to run without
external dependencies. Off-cluster Garage on `localhost:3900` provides the S3
API with zero cloud cost and no network requirement.

---

## `generate "backend"` over `remote_state`

Terragrunt offers two ways to configure the backend:

| Approach | Behaviour |
|---|---|
| `remote_state` block | Terragrunt manages the bucket — calls `CreateBucket` on first use. Garage partially supports the S3 API but returns unexpected responses to some bucket-management calls, causing silent failures or noisy errors. |
| `generate "backend"` block | Writes a `backend.tf` file before `terraform init`. Terraform handles the backend; Terragrunt is not involved in bucket creation. Works reliably against Garage because it only calls the bucket-exists / object-get / object-put path. |

We use `generate "backend"` (`infra/live/local/root.hcl`). The bucket and key are
pre-created by `scripts/tfstate-bootstrap.sh` (via `garage bucket create`), so
Terraform finds the bucket ready on first `init`.

**`-reconfigure` on every `init`.** A `terraform { extra_arguments "reconfigure" }` block
passes `-reconfigure` to every `init`. This is necessary because:
- Before this S3 backend existed the units used local state; `-reconfigure` re-binds
  the stale local-backend reference without prompting for a migration.
- If the `TFSTATE_ENDPOINT` env changes (e.g. CI vs local), `-reconfigure` picks up
  the new endpoint cleanly.

---

## State locking: explicitly disabled

Terraform supports S3-native state locking via `.tflock` objects or DynamoDB.
Garage does not honour the `.tflock` path consistently — Terraform 404s when
releasing the lock, leaving state locked and blocking the next apply.

**Decision: do not use `use_lockfile` or DynamoDB locking.** The lab is
single-operator and runs applies sequentially; concurrent writes cannot occur.
The `root.hcl` comment `# Do NOT re-add use_lockfile` records this so future
editors don't reintroduce it thinking it's an oversight.

For a real multi-operator setup: use a DynamoDB-compatible lock table or a
Garage fork/version that fully implements `.tflock`; or switch to a native S3
backend that supports locking (AWS S3 + DynamoDB).

---

## Relationship to existing ADRs

| ADR | Relationship |
|---|---|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | The off-cluster Garage is **bootstrap substrate** (day-0 seam), not a workload — consistent with ADR-0001's rule that Terraform only bootstraps. It is never registered as an ArgoCD Application. |
| [ADR-0002](adr-0002-garage-not-minio.md) | Same engine (Garage) for the same reason (lightweight, actively maintained, MinIO is out). Two instances, two purposes: this ADR covers the state backend; ADR-0002 covers the in-cluster object store. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | The off-cluster state Garage is a SPOF by position in the bootstrap chain (you can't apply without it), but the appropriate mitigation is recreate-from-code (ADR-0005): if the Docker volume is lost, `make tfstate-up && make tfstate-bootstrap` rebuilds an empty store; the next `terragrunt apply` repopulates it from live infrastructure. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | On a single host, adding a second state Garage replica provides no protection against the host failure; recreate-from-code is the correct response. |

---

## Files

| Path | Role |
|---|---|
| `infra/tfstate/docker-compose.yml` | Defines the `tfstate-garage` container |
| `infra/tfstate/garage.toml` | Garage config (S3 API on `:3900`, single-node `dc1`) |
| `scripts/tfstate-bootstrap.sh` | Idempotent layout → key import → bucket create + grant |
| `infra/live/local/root.hcl` | `generate "backend"` + `-reconfigure` shared across all Terragrunt units |

Brought up via `make tfstate-up`; torn down via `make tfstate-down` (stops the
container; the Docker volume `tfstate_data` persists until `make tfstate-clean`).
