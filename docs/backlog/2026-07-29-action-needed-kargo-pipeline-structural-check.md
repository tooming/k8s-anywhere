# [Action needed] Now/next still gated; Kargo promotion-pipeline structural consistency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#855](https://github.com/tooming/k8s-anywhere/pull/855) (Terraform
variable-to-Terragrunt-input wiring audit).

## This cycle's fresh angle

Read `gitops/kargo-project/project.yaml` (Kargo's `Warehouse` + `dev`/`prod`
`Stage` definitions, ADR-0023) end to end — a component this run hadn't
directly inspected yet. Checked the `Warehouse`'s subscription source
(`artifactory.127.0.0.1.nip.io/docker-local/hello`) matches what both
`Stage`s' `requestedFreight` sources reference, and that both in turn match
the image ref actually hardcoded in `gitops/apps/capstone/{deployment,
rollout}.yaml` (re-confirmed this cycle: still
`artifactory.127.0.0.1.nip.io/docker-local/hello:latest`, consistent with
the still-open `:latest` Kyverno carve-out an earlier cycle this run
verified). All three references line up. No structural mismatch.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct component
(Kargo's promotion pipeline, not previously inspected this run) checked for
structural consistency, clean. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
