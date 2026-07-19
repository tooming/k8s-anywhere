# Add a mechanical guard against stale ADR "Follow-up:" promises

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b after the executor's own lane, and the
planner/architect/upgrade-drafter fallbacks, all came up with no further real
deliverable this run.)

Earlier this run's history (PR merging `auto/adr-0006-stale-followup-note`) found
that ADR-0006's `## Decision` §Status paragraph carried a stale, unchecked
parenthetical — "(Follow-up: wire both bootstraps into `make up`/DR.)" — long after
both bootstraps were actually wired in. Nothing mechanical caught the drift; it
took a manual gap-analysis pass to notice. That item's own text flagged a
recurrence guard as valuable but left it undone ("optional, not required to land
this fix"). This closes that gap: a promise written as ADR prose has no mechanism
forcing anyone to re-check it, so the fix is to make the class of bug detectable,
not to trust future authors to remember.

Added, mirroring this repo's existing drift-guard pattern (`roadmap-check.sh` was
the closest structural analog — a single-file text-content check):

- `scripts/adr-followup-check.sh` — fails if any `docs/decisions/adr-*.md` file
  contains the literal string `Follow-up:`. Supports an `ADRFOLLOWUPCHECK_ROOT`
  override for fixture-driven tests, matching every other drift detector's
  convention.
- `make adr-followup-check` target + wired into `make ci`'s recipe.
- `.github/workflows/ci.yml`: the identical `bash scripts/adr-followup-check.sh`
  step, keeping `make ci` and CI in parity (enforced mechanically by the existing
  `ci-parity-check.sh` gate, which caught the omission immediately via its
  PostToolUse hook when this script was first added to the Makefile).
- `scripts/adr-followup-sync-hook.sh` — PostToolUse hook wired in
  `.claude/settings.json`, reacting only to edits under `docs/decisions/`, so a
  future session gets an immediate nudge instead of waiting for CI.
- `tests/drift-detectors.bats`: three new assertions (passes on an in-sync
  fixture, fails on a drift fixture asserting the `Follow-up` string appears in
  the failure output, passes on the real repo's `docs/decisions/`) plus two new
  fixture trees under `tests/fixtures/adr-followup-check/{in-sync,drift}/`.

Behavior-preserving: no existing check's pass/fail set changed; this only adds a
new, previously-nonexistent gate. Verified directly (ADR-0004) that the real repo's
current `docs/decisions/` is clean (the guard passes) before landing it.

`make ci` passes.

## PR

(filled in after PR creation)
