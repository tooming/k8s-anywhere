# Add a PostToolUse nudge hook for dependency-register-check.sh

(CHARTER **Core Values** §"Docs & dashboards don't drift"; JANITOR-fallback
bounded cleanup 2026-08-24, fourth cycle of this run, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed
fully gated and this same run's PLANNER/ARCHITECT/JANITOR fallback passes
each already produced their own real deliverable — dependency-register.md
drift fix + `make ci` guard (PR #1297), the weekly industry digest (PR
#1298), a stale doc-Gap-line fix (PR #1299) — with nothing further to groom,
decide, or bump this cycle. **No prerequisites — executor may pick up
immediately.**)

## What was found

`scripts/dependency-register-check.sh` (shipped this run's first cycle, PR
#1297) closes the `make ci` half of CLAUDE.md's "every bugfix must prevent
recurrence" pattern for `docs/dependency-register.md` staleness — but the
repo's own established convention for this exact pattern (see
`context-doc-version-sync-check.sh` / `adr-chart-version-sync-check.sh` and
their sibling `*-sync-hook.sh` files) pairs every such `make ci` gate with a
**local PostToolUse hook** that nudges immediately at edit time, not only on
the next `make ci` run — closing the loop faster and matching CLAUDE.md's
explicit "CI gate + a hook that nudges at edit/push time" mechanical-guard
order. `scripts/dependency-register-check.sh` had the gate but no
corresponding hook — a gap in its own delivery, caught this cycle.

## What changed

- New `scripts/dependency-register-sync-hook.sh`: fires on edits to
  `docs/decisions/*` or `docs/dependency-register.md` itself, re-runs
  `dependency-register-check.sh`, and surfaces its output as a PostToolUse
  nudge (exit 2) if a row has gone stale. Mirrors
  `context-doc-version-sync-hook.sh`'s exact shape.
- Registered in `.claude/settings.json`'s `PostToolUse` array, alongside the
  existing sibling hooks.
- New `tests/hook-scripts-dependency-register-sync.bats` (5 tests, per the
  `hook-scripts-coverage.bats`-is-frozen convention: new hook-script coverage
  goes in its own file) — empty/unrelated-file/real-ADR/real-register-file
  exit-0 cases, plus a drift fixture (reusing
  `tests/fixtures/dependency-register-check/drift/` from PR #1297) proving
  the exit-2 nudge path actually fires.

## Verification

`bash tests/hook-scripts-dependency-register-sync.bats` — 5/5 pass. `make ci`
green (including `hook-scripts-coverage-tests-check`, `readme-check`, and a
`.claude/settings.json` JSON-validity spot-check). Behavior-preserving:
no existing hook, gate, or test changed; this only adds new, previously-
absent coverage.

## PR

chore/dependency-register-sync-hook
