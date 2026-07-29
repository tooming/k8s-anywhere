# Backfill docs/done/ PR links + add a recurrence guard

Autonomous executor run, **JANITOR fallback lens** (STEP 6b) — the "Now / next"
lane was starved (all remaining items gated on standing maintainer-confirmation
issues), and the planner/architect/upgrade-drafter/doc-drift-author/triager
fallbacks ahead of janitor in the chain each came up clean this cycle (no
ungroomed issues, no un-RFC'd 🟡 items beyond what a prior cycle this run
already resolved, no available same-source dependency bump not already
covered by today's extensive sweeps, no README/lab-UI/dependency-tree drift,
and every open issue already fully triaged).

## What was found

Every `docs/done/*.md` file's template ends with a `## PR` section meant to be
backfilled with the real PR link once `gh pr create`/`create_pull_request`
returns a number — the number isn't known when the file is first committed
(it's part of the same PR that hasn't opened yet). A sweep of the real
`docs/done/` tree found **39 files**, spanning **2026-07-11 through
2026-07-29** (the file this same run's own prior cycle just created included),
where that placeholder was **never once resolved** after the PR actually
opened — every one of the three placeholder shapes seen in the wild
(`<!-- filled in after PR creation -->`, `(filled in after PR creation)`,
`(filled in once the PR is opened — see \`branch-name\`)`) just sat there
permanently. This is exactly CLAUDE.md's "a class of bug that has already
recurred without a mechanical guard" — the highest-priority janitor target —
not a one-off oversight.

## Fix

Backfilled all 39 files with the real PR link (`[#NNN](https://github.com/
tooming/k8s-anywhere/pull/NNN)`), resolved mechanically: for each file, walked
`git log --follow --diff-filter=A` to the commit that first added it, and
extracted the PR number from that commit's own squash-merge message suffix
(`... (#NNN)`) — every commit in this repo's history is a squash-merged PR, so
this is a reliable, verifiable mapping, not a guess (ADR-0004: every number
cited is the real originating commit's own PR reference).

## Guard (prevents recurrence)

New `scripts/docs-done-pr-link-check.sh`: fails if any `docs/done/*.md` file
still carries one of the three known placeholder shapes. Wired into
`make ci` (`docs-done-pr-link-check` target, both `make ci` and
`.github/workflows/ci.yml`'s `drift` job, kept in parity) and as a
`PostToolUse` hook (`scripts/docs-done-pr-link-sync-hook.sh`, registered in
`.claude/settings.json`, fires on edits under `docs/done/`) — mirrors the
existing `adr-followup-check` / `adr-chart-version-sync-check` drift-guard +
hook pattern exactly.

This is enforceable without weakening any other gate: CI reruns on every push
to a PR, and the self-review/self-merge contract only requires the *latest*
run green — so a routine has the same opportunity every other doc-drift gate
here relies on (push the placeholder on the first commit, open the PR, push a
follow-up commit once the number is known, watch this check turn green, then
self-review/merge). The check is network-tolerant and requires no cluster.

New bats coverage: `tests/docs-done-pr-link-check.bats` (fixture-based,
mirrors `tests/drift-adr-sync-checks.bats`'s pattern — in-sync case, each of
the three placeholder shapes, a missing-directory no-op, and a pass against
the real post-backfill repo) and `tests/hook-scripts-docs-done-pr-link.bats`
(its own file per the now-frozen `tests/hook-scripts-coverage.bats`
convention — empty payload, unrelated file, a real clean file, and a fixture
triggering the exit-2 nudge).

## Scope discipline

Bounded to exactly this one cleanup: the 39-file backfill (a pure data
correction, no prose reworded beyond the placeholder line itself) plus the
guard that stops it recurring. No topology change, no other file touched
beyond the check/hook scripts and their wiring (`Makefile`,
`.github/workflows/ci.yml`, `.claude/settings.json`) and their tests.

`make ci` must pass.

## PR

(filled in after PR creation)
