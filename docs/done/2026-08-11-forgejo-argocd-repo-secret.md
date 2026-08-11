# Wire ArgoCD's repo-credential Secret for the Forgejo remote (prep slice)

Wire ArgoCD's repo-credential Secret for the Forgejo remote (prep slice) — split from
this list's original single item via ROADMAP rule #9's split-the-gate judgment
(2026-08-11, reached via `executor.prompt.md` STEP 3 — this was the topmost unchecked
item and no open PR claimed it): repointing `Application` `repoURL`s (including
`root-app.yaml`, the always-on-synced app-of-apps entrypoint) is exactly the
live-reconcile-affecting "flip" rule #9 says must stay gated for a clusterless session —
ArgoCD would attempt to re-sync every Application from Forgejo on the next live
reconcile, and neither the Forgejo repo's content (no `forgejo-push` mechanism exists
yet — that's a later migration item) nor its CI/runner (the prior migration item's own
`docs/done` record: unverified) are confirmed live-working. Building that flip anyway
would risk the same fleet-wide blast radius the cosign `enforce-flip` slice was split
out to avoid (RFC #214 precedent, cited by the prior migration item). What *is* safe and
additive: `infra/modules/forgejo-config`'s `kubernetes_secret.argocd_repo` resource
(SSH-keyed, named `repo-forgejo-gitops` — distinct from the still-used
`repo-gitlab-gitops`) plus the `repo_url_in_cluster`/`argocd_namespace` variables and
both live Terragrunt units' `kubernetes` provider wiring, all parallel to the
predecessor module's own resource shape. No `gitops/**/*.yaml` Application references
the new URL yet, so this is inert until the next item flips it — `make ci` (kubeconform,
kustomize, terraform fmt/validate, bats) confirms the module is well-formed without
needing a live cluster.

This is migration stage 4a (of what was a 6-item, now 7-item, list) in the "GitLab →
Forgejo migration" list (ROADMAP.md, ADR-0035).

## What's here

- `infra/modules/forgejo-config/main.tf` — adds the `hashicorp/kubernetes` required
  provider and a `kubernetes_secret.argocd_repo` resource: an ArgoCD repository-type
  Secret (`argocd.argoproj.io/secret-type: repository`) named `repo-forgejo-gitops`,
  carrying `type=git`, `url=var.repo_url_in_cluster`, `sshPrivateKey` (the same
  `tls_private_key.argocd_deploy` the existing `forgejo_deploy_key` resource already
  registers on the repo), and `insecure="true"` (skips ArgoCD's SSH known-hosts check —
  `host.k3d.internal` never leaves the Colima VM, same trust model as Harbor's
  TLS-disabled minimal profile, ADR-0024).
- `infra/modules/forgejo-config/variables.tf` — adds `argocd_namespace` (default
  `"argocd"`) and `repo_url_in_cluster` (default
  `ssh://git@host.k3d.internal:2223/lab/k8s-lab.git`, matching
  `forgejo/docker-compose.yml`'s SSH port mapping) variables, mirroring the predecessor
  `gitlab-config` module's variables of the same names/shape (adjusted for SSH instead
  of HTTP transport, since `svalabs/terraform-provider-forgejo` v1.5.2 has no
  HTTP-token deploy-credential resource — only `forgejo_deploy_key`, SSH).
- `infra/live/local/forgejo/terragrunt.hcl` and `infra/live/oracle/forgejo/terragrunt.hcl`
  — add a `dependency "cluster"` block and a `kubernetes` provider `generate` block,
  mirroring the predecessor `gitlab-config` live units exactly (needed because this
  module now creates a Kubernetes resource, not just Forgejo-API resources).
- `tests/forgejo-config.bats` — replaces the now-stale "does not manage a
  kubernetes_secret (out of scope for this item)" guard (that scope boundary was this
  item's own predecessor's) with coverage for the new resource: the kubernetes provider
  and `kubernetes_secret.argocd_repo` resource exist; the Secret is SSH-keyed, named
  distinctly from the still-live `repo-gitlab-gitops`, and no `gitops/**/*.yaml`
  Application yet references the new host/port; both Terragrunt units declare the
  cluster dependency and kubernetes provider.

## Deliberately NOT done here (the gated slice, tracked as its own ROADMAP item)

Flipping `gitops/**/*.yaml` Application `repoURL`s (61 occurrences across ~54 files,
including `gitops/bootstrap/root-app.yaml`, the always-on-synced entrypoint every other
Application effectively descends from) to actually use this new credential. That flip:

1. Needs the Forgejo repo to actually hold this repo's content — no push has happened
   yet (no automated mechanism exists; a later migration item renames
   `scripts/gitlab-push.sh` → `scripts/forgejo-push.sh`, though a plain `git remote add`
   + `git push` would also work sooner).
2. Needs `infra/modules/forgejo-config` actually `terraform apply`'d against a live
   cluster so the `repo-forgejo-gitops` Secret this PR adds actually exists in-cluster.
3. Needs `.forgejo/workflows/build-sign-push.yml` (the prior migration item) confirmed
   running for real — currently unverified per that item's own `docs/done` record.
4. Needs a live ArgoCD sync verified afterward (the item's own explicit requirement,
   ADR-0004) — something this remote, clusterless session structurally cannot do.

Attempting the flip without all four would risk exactly the kind of fleet-wide
live-cluster breakage ROADMAP rule #9 exists to prevent (mirrors the cosign
`make-up-wiring`/`ci-sign-step`/`enforce-flip` split, RFC #214). The next migration list
item ("Flip `Application` `repoURL`s...") tracks this explicitly and stays unchecked
until a live-cluster session can do it safely.

## Verification (ADR-0004)

`make ci` passes locally with `terraform`, `bats`, `kustomize`, `kubeconform`,
`shellcheck`, and `yamllint` installed for this session (none of these ship in the base
remote environment): `terraform fmt`/`validate` succeed for the module (provider
registry initialization itself is unreachable from this sandboxed session — the gate
treats that as a skip, not a failure, per its own documented behavior — but `fmt` and
the HCL's static shape are checked), all 2618 bats tests pass, kustomize/kubeconform
builds are unaffected (this PR touches no `gitops/` manifest). What is **not** verified,
and cannot be from here: that `terraform apply` actually succeeds against a live
Forgejo + cluster, or that the resulting Secret is one ArgoCD actually accepts (schema
matches ArgoCD's documented SSH repository-credential Secret shape, but has not been
exercised against a real ArgoCD `repo-server`).

Rollback path: revert this PR — every change here is additive (a new Terraform resource
+ two new variables + two `generate` blocks), and nothing in the live cluster or the
still-used `repo-gitlab-gitops` Secret is touched.

## PR

[#1110](https://github.com/tooming/k8s-anywhere/pull/1110)
