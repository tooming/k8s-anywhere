# ADR-0007 — Off-cluster Garage as the Terraform-state backend

**Status.** Removed 2026-09-07 (maintainer decision — component dropped from the lab
entirely, no replacement). The off-cluster tfstate Garage was removed alongside Garage
itself (ADR-0002) and s3manager (ADR-0039) in the same change: `infra/tfstate/` (the
whole directory — `docker-compose.yml`, `garage.toml`) and `scripts/tfstate-bootstrap.sh`
were deleted. `infra/live/local/root.hcl` was migrated to a `backend "local"` (plain file
per Terragrunt unit, via `get_terragrunt_dir()`) in the **same change** — checked directly
against the real file, confirmed no `s3`/Garage backend reference remains anywhere under
`infra/live/local/`. (This paragraph previously said the migration was "not done as part
of this removal... a separate, coordinated follow-up" — that was wrong the moment it was
written; corrected 2026-09-07.) The Oracle backend
(`infra/live/oracle/root.hcl`) is unaffected — it uses its own separate, still-live
off-cluster Garage instance (`infra/tfstate-oracle/`, RFC #377 item 3), untouched by this
removal; whether that design should also be reconsidered is a distinct, still-open
question (see CHARTER.md's Oracle-backend bullet). The decision record below is kept for
history (why an off-cluster Garage was chosen over in-cluster Garage or a hosted S3
bucket) but no longer describes anything live under `infra/live/local/` — do not treat
any manifest path or Makefile target named below as still existing for the local
backend.

~~**Status.** Adopted. Shipped in commit `a07a1d2`; active in `infra/live/local/root.hcl`,
`infra/tfstate/`, `scripts/tfstate-bootstrap.sh`, make tfstate-up.~~

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
| [ADR-0003](adr-0003-decoupled-no-spof.md) | The off-cluster state Garage is a SPOF by position in the bootstrap chain (you can't apply without it), but the appropriate mitigation is recreate-from-code (ADR-0005): if the Docker volume is lost, running tfstate-up then tfstate-bootstrap (targets since removed, see Status above) rebuilds an empty store; the next `terragrunt apply` repopulates it from live infrastructure. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | On a single host, adding a second state Garage replica provides no protection against the host failure; recreate-from-code is the correct response. |

---

## Files

| Path | Role |
|---|---|
| `infra/tfstate/docker-compose.yml` | Defines the `tfstate-garage` container |
| `infra/tfstate/garage.toml` | Garage config (S3 API on `:3900`, single-node `dc1`) |
| `scripts/tfstate-bootstrap.sh` | Idempotent layout → key import → bucket create + grant |
| `infra/live/local/root.hcl` | `generate "backend"` + `-reconfigure` shared across all Terragrunt units |

Was brought up via tfstate-up; torn down via tfstate-down (stopped the
container; the Docker volume `tfstate_data` persisted until tfstate-clean) —
all three Makefile targets were removed along with the rest of this backend
(see Status above).

---

## Re-evaluation log

**2026-09-07 — Oracle backend's own tfstate Garage: audited, kept.** Trigger:
CHARTER.md's "Cloud backend" bullet flagged, as a genuinely open question
left by the 2026-09-06/2026-09-07 simplification, whether
`infra/live/oracle/root.hcl`'s own separate off-cluster Garage instance
(`infra/tfstate-oracle/`, RFC #377 item 3) should also be reconsidered now
that the local backend's equivalent (this ADR's own subject) was removed.

**Decision: Keep, unchanged.** The two instances were removed for
different, non-transferable reasons and the removal reasoning for one does
not carry over to the other:

- The **local** backend's off-cluster Garage was removed because its
  *consuming context* disappeared — Velero backups, Harbor's registry
  storage, and s3manager's browsing UI (the actual users of in-cluster
  Garage, ADR-0002) were all removed the same day, and the local host was
  independently found, with live evidence (`docs/incident-log.md`'s
  2026-09-06 entries: Harbor alone spiking load average to 238), to be
  capacity-constrained running the full prior stack on one 12 GB VM. A
  plain local-file Terraform backend is a strict simplification with no
  loss of capability for a single-host, single-operator lab (ADR-0005).
- The **Oracle** backend's off-cluster Garage serves a use case that never
  went away: durable state for a cloud-hosted target that may be applied
  from a different workstation/session than the one that created it. A
  plain local-file backend is the *wrong* fit here specifically because
  it isn't local to any one machine — losing a shared, durable state store
  would be a real regression for this backend, not a simplification.
- The Oracle backend's tfstate Garage runs on its **own, separate Always
  Free AMD Micro instance** — it never shared host capacity with the local
  lab's 12 GB VM, so the specific capacity pressure that motivated removing
  the local backend's Garage does not apply here at all. There is no
  equivalent "component straining the host" finding to act on.

**Flip condition:** revisit if (a) the Oracle backend itself is ever
removed (nothing left to hold state for), or (b) a simpler, still-durable,
still-shared-across-sessions state mechanism becomes practical for a
cloud-hosted Terragrunt unit (e.g., if Oracle's own free-tier object
storage becomes a viable Terraform S3-compatible backend directly, removing
the need for a dedicated Garage instance at all) — not before either
condition is concretely true.
