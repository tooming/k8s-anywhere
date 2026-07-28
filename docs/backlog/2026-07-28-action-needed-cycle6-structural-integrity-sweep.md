# [Action needed] Now/next still gated; structural-integrity sweep clean (beyond the merged janitor fix)

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has already shipped five real, merged deliverables:
`upgrade/*` PRs #789 (Alloy chart) and #790 (Grafana chart); PR #792 (filed issue #791,
Terraform provider major-version gaps); PR #793 (a hardening/doc-precision sweep, cycle 4);
and `chore/*` PR #794 (a janitor cleanup — dropped a permanently-dead `skip` guard from
`tests/cosign-bootstrap.bats`, found via a bounded scan of every `skip` directive across
`tests/*.bats`).

This cycle extended the janitor-lens dead-code search with three additional structural
checks, distinct from cycle 4's ADR/Objective/TODO/doc-precision lenses:

1. **Stale-conditional-phrasing sweep** (`pending.*merge`, `not yet on branch`, `not yet
   implemented`, `not yet built`) across `tests/` and `scripts/` — the only remaining
   hits are three `*-tests-sync-hook.sh` scripts whose "FROZEN... prevents the recurring
   ...merge conflict" messaging is evergreen guidance (not a stale reference to a specific
   pending PR), unlike the `cosign-bootstrap.bats` guard fixed this run. No new dead
   conditional found.
2. **Orphaned-script check** — every file under `scripts/*.sh` is referenced by at least
   one of `Makefile`, another script, a GitHub Actions workflow, a doc, or a test. No
   orphaned script found.
3. **Kustomization resource-integrity check** — every `resources:` entry in every
   `gitops/**/kustomization.yaml` resolves to a real file/directory relative to its own
   kustomization. No broken resource reference found.

No further actionable gap surfaced from any of the three lenses this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
