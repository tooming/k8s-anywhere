# `infra/modules/forgejo-config` Terraform module

`infra/modules/forgejo-config` Terraform module — org/repo/branch-protection/
deploy-token resources via `svalabs/terraform-provider-forgejo` (or
`adyxax/terraform-provider-forgejo` if its resource coverage fits better — check both
before committing), `infra/live/{local,oracle}/forgejo/`. Parallels `gitlab-config`.
Prerequisite: previous item (needs a live Forgejo instance to point Terraform at).

This is migration stage 2 of 6 in the "GitLab → Forgejo migration" list
(ROADMAP.md, ADR-0035).

## Provider choice

Checked both providers' resource coverage directly against their published docs
before committing, as the ROADMAP item required:

- **`svalabs/terraform-provider-forgejo`** — has `organization`, `repository`,
  `branch_protection`, `deploy_key`, `collaborator`, `user`, plus team/webhook/secret
  resources. Covers all four resource categories this item asks for.
- **`adyxax/terraform-provider-forgejo`** (v1.5.4) — has `organization`,
  `repository`, `team`, and repository action secrets/variables/push-mirrors, but
  **no `branch_protection` and no deploy-token-equivalent resource**.

`svalabs` was the only one of the two with real branch-protection and
deploy-credential coverage, so it's what this module uses.

**Correction during this item (caught by live CI, not this clusterless session):**
the first attempt pinned `svalabs/forgejo ~> 1.5` and used a `forgejo_personal_access_token`
resource scoped to a dedicated `argocd-ro` bot user. That resource only exists on the
provider's unreleased `main` branch — CI's real `terraform init` against the actual
registry (latest published: v1.5.2) failed with "provider svalabs/forgejo does not
support resource type forgejo_personal_access_token". This session's own doc fetches
(the provider's GitHub `main`-branch docs) didn't distinguish released-vs-unreleased
resources; CI's live registry access did. Replaced with `forgejo_deploy_key` (SSH,
repository-scoped — confirmed present in the real v1.5.2 tag), which is actually a
closer parity match for the predecessor module's project-scoped deploy token than a
user-scoped PAT would have been.

## What's here

- `infra/modules/forgejo-config/{main,variables,outputs}.tf` — `forgejo_organization`,
  `forgejo_repository`, `forgejo_branch_protection`, and a `forgejo_deploy_key`
  (paired with a Terraform-generated ED25519 keypair via the `hashicorp/tls`
  provider) scoped read-only to the repository. ArgoCD supports SSH repository
  credentials natively (`sshPrivateKey` on the repo Secret), so this is a usable
  substitute for the predecessor module's HTTP deploy token, not a downgrade.
- `infra/live/{local,oracle}/forgejo/terragrunt.hcl` — both identical (matching
  `infra/live/README.md`'s existing "units never change per backend" contract),
  pointing the module at `http://localhost:3300` (the Forgejo compose stack's host
  port, ROADMAP migration item 1). Runs under basic-auth against the `lab-admin`
  account (`scripts/forgejo-env-ensure.sh` + `forgejo-admin-ensure.sh`) — there is no
  PAT-minting script for Forgejo yet, unlike the predecessor module's token-based
  provider.
- `tests/forgejo-config.bats` — clusterless structural coverage: the module declares
  the `svalabs/forgejo` provider and all four resource categories, the repository is
  private, the deploy key is read-only and repository-scoped, no `kubernetes_secret`
  is created (out of scope for this item — that's a later migration item), and both
  live units source the module correctly.

## Scope note

This module does **not** create an ArgoCD-facing `kubernetes_secret` or touch the
cluster in any way — only org/repo/branch-protection/deploy-token config against the
Forgejo instance itself, per this item's own explicit scope. Re-pointing ArgoCD's
repository credential and `Application`s at this remote, verified live, is a later
item in the same migration list.

## Verification (ADR-0004)

Clusterless session — no live Forgejo instance or local `terraform`/registry access.
GitHub Actions CI (which does have real registry access) provided the only live
signal available: `terraform fmt`/`terraform validate`/`tflint` against the actual
published `svalabs/forgejo` provider caught both a formatting mistake and the
unreleased-resource mistake documented above — that CI feedback loop is what this
item actually leaned on for correctness, not this session's own (registry-egress-
blocked) judgment. **Not verified**: an actual `terraform apply`/`plan` against a
live Forgejo instance — that needs a running Forgejo container this session has no
access to. Rollback path: revert this PR — no live Forgejo state exists for
`svalabs/forgejo` to have created against, since no `terragrunt apply` has run yet.

## PR

[#1107](https://github.com/tooming/k8s-anywhere/pull/1107)
