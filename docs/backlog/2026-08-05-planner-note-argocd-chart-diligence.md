# Planner note — 2026-08-05 (ArgoCD chart bump — completed diligence)

## What this run did

Reached the planner role again via `executor.prompt.md` STEP 6b, this run's
third cycle: "Now / next" was back to the same 3 items every recent cycle has
found gated (on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked fresh,
still open, no new comments since the last check). No new open GitHub issues
to groom.

Rather than re-run an identical currency sweep, this cycle finished the one
concrete, real, open follow-up the prior cycle's note
(`2026-08-05-planner-note-grafana-chart-currency.md`) explicitly left
outstanding: the Terraform-bootstrapped `argo-cd` chart `10.2.2`→`10.2.3`
delta (`appVersion` `v3.4.6`→`v3.5.0`, a **minor** ArgoCD release) — found but
deliberately not added to ROADMAP that cycle without first checking argo-cd's
own release notes for breaking changes, since ArgoCD is this lab's sole
reconciler (ADR-0001).

## What was found

Read ArgoCD's own official upgrade guide,
`docs/operator-manual/upgrading/3.4-3.5.md`, directly at the `v3.5.0` git tag
(not training knowledge, ADR-0004) — 672 commits sit between `v3.4.6` and
`v3.5.0`, including a `feat: Migrate from Helm 3 to Helm 4 (#28076)` commit,
which is exactly the kind of internal-engine change worth being cautious
about given how heavily this lab relies on Helm-sourced Applications.

The guide's own "Breaking Changes" section lists six items. Checked each
directly against this repo's actual `gitops/**/*.yaml` + `infra/**` config —
none apply here:

1. Helm v3→v4 plain-HTTP OCI registries need `--insecure-oci-force-http`:
   zero `oci://` sources, zero `enableOCI` settings anywhere in this repo; the
   one OCI-shaped Application (`ack-s3.yaml`, AWS public ECR) is TLS-only by
   construction.
2. UI extensions (React 16→19): no custom extensions installed.
3. Event-listing gRPC response type change: no custom gRPC clients exist.
4. Impersonation extended to server ops: not enabled (no
   `destinationServiceAccounts` configured).
5. SSH `known_hosts` behavior change: every `repoURL` in this repo is
   `http://`/`https://`, zero `ssh://`/`git@` entries.
6. GnuPG signature verification → Source Integrity: no
   `AppProject.spec.signatureKeys` configured anywhere.

Combined with the prior cycle's chart-level finding (only `Chart.yaml` +
additive-only CRD fields changed, zero `values.yaml` diff — RFC #785's
`global.networkPolicy.create: false` companion override is untouched), this
is a genuinely safe bump for this lab's specific configuration, despite
looking risky on paper from the "minor ArgoCD release + Helm engine swap"
framing alone.

Added as a new 🟢 Now/next item (`auto/argocd-chart-10-2-3`) with the full
breaking-change checklist and implementation detail (three pin sites move
together — `infra/modules/argocd/variables.tf`, both `terragrunt.hcl` inputs
— per the recurrence guard already in `tests/argocd-chart-pin.bats` from the
9.x→10.x bump's own drift history).

## Why no other action this cycle

This is the honest, single deliverable: closing out a real, previously-flagged
follow-up with the actual diligence it needed, rather than leaving it to rot
as an unactioned note or re-sweeping components already confirmed current
today.

## What would unblock further Now/next work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633 — PR #980
is the maintainer's own live in-progress work toward that; (b) a new GitHub
issue of any size (ungroomed intake); (c) a new upstream CVE/release firing
one of the tracked ADR flip conditions.

This is this cycle's deliverable, not the run's stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8, which should
pick up the newly-added ArgoCD chart item directly.
