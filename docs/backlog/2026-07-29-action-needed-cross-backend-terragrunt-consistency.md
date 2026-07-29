# [Action needed] Now/next still gated; cross-backend Terragrunt consistency audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#840](https://github.com/tooming/k8s-anywhere/pull/840) (Vault ACL
policy least-privilege audit).

## This cycle's fresh angle

CHARTER.md's "Cloud backend" target end-state promises `gitops/` requires
**no fork** to run on either backend — the identical ArgoCD-managed stack
deploys to localhost or Oracle. No prior `docs/backlog/` note has directly
diffed the two `infra/live/{local,oracle}/` Terragrunt trees against each
other to verify that promise at the Terragrunt-input level (as opposed to
`gitops/` itself, which is backend-agnostic by construction and covered
elsewhere).

Diffed every shared unit (`root.hcl`, `argocd/terragrunt.hcl`,
`gitlab/terragrunt.hcl` — `cluster/terragrunt.hcl` is expected to differ
entirely, since it's a different Terraform module per backend:
`k3d-cluster` vs. `oracle-k3s-cluster`):

- **`argocd/terragrunt.hcl`** — byte-identical `chart_version = "10.2.1"`
  input on both backends (matches this run's earlier finding that the
  `hashicorp/helm` provider constraint bump landed consistently on both).
- **`gitlab/terragrunt.hcl`** — byte-identical on both backends.
- **`root.hcl`** — the only differences are the expected backend-specific
  parameters: `cluster_name` (`k8s-lab` vs. `k8s-anywhere-oracle`) and the
  Terraform-state S3 endpoint env-var name (`TFSTATE_ENDPOINT` vs.
  `TFSTATE_ORACLE_ENDPOINT`) — both intentional, not drift.
- **`cluster/terragrunt.hcl`** — differs entirely as expected (different
  module source, different provider block, different inputs) — this is the
  one seam ADR-0026/ADR-0027 explicitly allow to vary per backend.

**Conclusion: no drift.** The two backends' shared units stay in lockstep;
the only differences anywhere are the deliberate backend-specific ones
CHARTER's own "Cloud backend" section already documents.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct check
(cross-backend Terragrunt input consistency, verifying CHARTER's
"identical stack, no fork needed" promise at the infra layer) that found no
drift. The run continues to the next cycle per `executor.prompt.md` STEP 8;
this is not a stopping point.
