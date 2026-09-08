# Add a `concurrency` group to `.github/workflows/ci.yml` to cancel superseded runs

Found live 2026-09-08 (JANITOR-fallback cleanup, cycle 19 of this run —
different lens: CI workflow configuration, not application/infra/doc
currency, both already swept clean this run in cycles 17-18):
`.github/workflows/ci.yml` had no `concurrency` group at all, so every push
to an open PR (a rebase, a self-review PR-link backfill commit, a fix-up
push) starts a brand-new full ~7-job CI run without cancelling the
now-superseded previous one — whose result nothing reads once the newer
commit lands anyway.

This is not a hypothetical edge case for this repo: its own self-merge
routines deliberately push twice per PR as standard practice — an initial
push with the docs/done "## PR" section carrying a placeholder, then a
backfill commit once `gh pr create`/`create_pull_request` returns the real
PR number (`scripts/docs-done-pr-link-check.sh`'s own header documents this
exact workflow: "push the placeholder, open the PR, push the backfill,
watch this check turn green, then self-review/merge"). This run alone did
that pattern on PRs #1514, #1515... (and every subsequent PR) — two full
CI runs each time, with the first one's result never actually mattering.

## What was done

Added a `concurrency` block keyed by `github.workflow` + the PR number (for
`pull_request` events) or the ref (for `push` events, scoped to `main`
only per this workflow's own existing `on:` restriction), with
`cancel-in-progress: true`. A newer commit for the same PR (or the same
`main` ref) now cancels any still-running check for the prior commit
instead of letting both run to completion. Unrelated PRs/branches use
different group keys, so they never cancel each other.

This strictly reduces wasted GitHub Actions compute; it does not weaken
any gate — the newest commit's own CI run is never itself cancelled (only
a now-superseded *older* run for the same PR/ref is), so "the latest
commit's checks must be green before merge" is completely unaffected.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green). `yq eval '.'
.github/workflows/ci.yml` confirms the YAML still parses correctly.
Behavior-preserving: no job, trigger, permission, or timeout changed —
only the new `concurrency:` top-level key was added.

## PR

[#1532](https://github.com/tooming/k8s-anywhere/pull/1532) (autonomous
scheduled executor run, cycle 19 — JANITOR-fallback, found via a CI
workflow-configuration lens after cycles 17-18's doc/infra currency sweeps
both came up clean).
