# Add `make dependency-concentration-sync-check` — a mechanical `make ci` guard closing the "no mechanical drift guard yet" gap across three dependency docs

(CHARTER **Core Values** §"Everything as code" (DORA audit readiness Q14/Q16/Q17);
planner-fallback gap analysis 2026-09-02, this run's fifth cycle, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
gated again this cycle and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER all came up empty again. Fresh angle: rather than a fourth pass mining
`docs/dora-audit-readiness.md` for another named prose gap, this cycle closed the
"no mechanical drift guard yet" limitation `docs/dependency-register.md`,
`docs/dependency-concentration.md`, and `docs/dependency-exit-runbooks.md` each
honestly self-flag in their own "Keeping this in sync" sections — the exact
CLAUDE.md bugfix-recurrence-prevention pattern (mechanical guard over a note to
remember). **No prerequisites — executor may pick up immediately.**)

## What was found

Three docs this run's earlier cycles already touched (PR #1375's
`dependency-maintenance-check.sh`, PR #1378's exit-runbook slice) each contain an
honest "Keeping this in sync" section stating no mechanical drift guard connects
`docs/dependency-register.md` (the source table) to `docs/dependency-concentration.md`
(its concentration-risk rollup, grouping rows by shared `github.com` org) or
`docs/dependency-exit-runbooks.md` (in turn downstream of the concentration
groups). A register edit that changes an org's row count (a new tool added under
an existing org, or an org's last remaining row removed) has nothing today that
would catch a stale concentration-file entry.

## Fix

Unlike `dependency-maintenance-check.sh` (needs real network access to check
upstream repo activity, deliberately kept out of `make ci`), this new check is
pure text-parsing over two already-committed docs — fast, deterministic,
network-free — so it's wired directly into `make ci` and
`.github/workflows/ci.yml`'s `drift` job, same tier as `dependency-register-check.sh`.

`scripts/dependency-concentration-sync-check.sh` counts how many
`docs/dependency-register.md` rows share each `github.com` upstream org and fails
if any org backing 2+ rows (a real concentration point per
`docs/dependency-concentration.md`'s own "Method" section) isn't named there.
Scope is deliberately partial, matching this repo's other partial-coverage drift
guards (e.g. `adr-chart-version-sync-check.sh` only checks ADRs that self-declare
a chart-version note): it does not check the reverse (a concentration-file entry
with no matching register rows) or `dependency-exit-runbooks.md`'s own downstream
sync — both real, separately-scoped gaps.

**De-duplication caught proactively, not reactively:** this check needs the exact
same docs/dependency-register.md table-parsing logic `dependency-maintenance-check.sh`
already had inline. Rather than write a second near-identical copy — the exact
"two copies of a parser" class CLAUDE.md's mechanical-guard/de-duplication
principle exists to catch — extracted `depreg_rows()`/`depreg_github_match()`
into `scripts/lib/dependency-register.sh` first, and refactored
`dependency-maintenance-check.sh` to source it too. Verified the refactor is
behavior-preserving: same output against the same fixture, same 6/6 bats pass.

Added `scripts/dependency-concentration-sync-hook.sh` (PostToolUse nudge,
mirrors `dependency-register-sync-hook.sh`'s existing pattern exactly) wired in
`.claude/settings.json`. Added bats coverage: `tests/dependency-register-lib.bats`
(the new shared lib), `tests/dependency-concentration-sync-check.bats` (the new
check, both in-sync and drift fixture paths), and
`tests/hook-scripts-dependency-concentration-sync.bats` (the new hook, per the
`hook-scripts-coverage-tests-check` convention that new hook coverage goes in its
own file, not the frozen `tests/hook-scripts-coverage.bats` monolith).

`make ci` / local: full lint (shellcheck + yamllint), `ci-parity-check` (make ci
and GitHub Actions run the same gate set), and all new/refactored bats files
green (18 tests across the three new/touched files).

**ADR-0004 caveat:** none needed beyond the usual — this is a pure text-parsing,
clusterless, network-free check; nothing here depends on live-cluster state.

## PR

https://github.com/tooming/k8s-anywhere/pull/1379
