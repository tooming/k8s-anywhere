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

- **`svalabs/terraform-provider-forgejo`** (v1.5.0) — has `organization`,
  `repository`, `branch_protection`, `deploy_key`, `personal_access_token`,
  `collaborator`, `user`, plus team/webhook/secret resources. Covers all four
  resource categories this item asks for.
- **`adyxax/terraform-provider-forgejo`** (v1.5.4) — has `organization`,
  `repository`, `team`, and repository action secrets/variables/push-mirrors, but
  **no `branch_protection` and no deploy-token-equivalent resource**.

`svalabs` was the only one of the two with real branch-protection and
deploy-credential coverage, so it's what this module uses.

## What's here

- `infra/modules/forgejo-config/{main,variables,outputs}.tf` — `forgejo_organization`,
  `forgejo_repository`, `forgejo_branch_protection`, and a `forgejo_personal_access_token`
  scoped read-only to a dedicated `argocd-ro` bot user (`forgejo_user` +
  `forgejo_collaborator`). svalabs/terraform-provider-forgejo has no project-scoped
  deploy-token resource the way the module ADR-0035 supersedes did; its `deploy_key`
  resource is an SSH public key, not the HTTP-basic-usable credential ArgoCD's
  git-over-HTTP clone needs, so a minimal restricted bot user + PAT stands in for it.
- `infra/live/{local,oracle}/forgejo/terragrunt.hcl` — both identical (per
  `infra/live/README.md`'s "argocd/gitlab units never change per backend" contract,
  now extended to this unit too), pointing the module at `http://localhost:3300`
  (the Forgejo compose stack's host port, ROADMAP migration item 1).
- `tests/forgejo-config.bats` — clusterless structural coverage: the module declares
  the `svalabs/forgejo` provider and all four resource categories, the repository is
  private, no `kubernetes_secret` is created (out of scope for this item — that's a
  later migration item), and both live units source the module correctly.

## Scope note

This module does **not** create an ArgoCD-facing `kubernetes_secret` or touch the
cluster in any way — only org/repo/branch-protection/deploy-token config against the
Forgejo instance itself, per this item's own explicit scope. Re-pointing ArgoCD's
repository credential and `Application`s at this remote, verified live, is a later
item in the same migration list.

## Verification (ADR-0004)

Clusterless session, no live Forgejo instance or Terraform/network access here — this
was validated structurally only: `terraform fmt` alignment computed and checked by
hand (Terraform is not installed in this remote environment), and the new
`tests/forgejo-config.bats` file's assertions (see above). **Not verified**: an actual
`terraform apply` against a live Forgejo instance. Rollback path: revert this PR — no
Forgejo state exists yet for `svalabs/forgejo` to have created against the live
instance until a real `terragrunt apply` is run, which hasn't happened.

## PR

(filled in after PR creation)
