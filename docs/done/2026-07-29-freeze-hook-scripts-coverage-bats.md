# Freeze tests/hook-scripts-coverage.bats — split-target mechanical guard

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Janitor fallback cleanup (`executor.prompt.md` STEP 6b) after
the "Now / next" lane came up fully gated on standing maintainer-confirmation
issues #631/#632/#633, and this run's planner (gap analysis — found and fixed
the `docs/dependency-tree.md` cert-manager/KEDA drift, PR #865) and
doc-drift-author fallback lenses already produced their own deliverables this
run; a fresh sweep of the remaining fallback lenses (architect: no un-RFC'd
🟡 items; upgrade-drafter: Cilium's `v1.17.18` pin was re-audited and kept as
recently as 2026-07-28 per ADR-0014's own Re-evaluation log; triager: only the
three standing `[Action required]` issues are open, already labeled) found
nothing further, landing on janitor as the next fallback.

## The footgun

`tests/hook-scripts-coverage.bats` had grown to 68 `@test` blocks across 18
unrelated PostToolUse/SessionStart hook scripts — its own header comment
frames it explicitly as catch-all coverage for "hook scripts that had zero
bats coverage," so every new hook lands its own `@test` section at the file's
EOF. This is already bigger than `tests/securitycontext.bats` (33 tests) or
`tests/drift-detectors.bats` (22 tests) were before each hit the exact "shared
monolith multiple PRs append to" footgun CLAUDE.md's bugfix-recurrence rule
calls out and got frozen with a mechanical guard — but
`hook-scripts-coverage.bats` had never received the same treatment.

## The fix

Mirrors the established `securitycontext-tests-check` / `observability-tests-check`
/ `drift-detectors-tests-check` pattern exactly:

- New `scripts/hook-scripts-coverage-tests-check.sh`: snapshots the sorted
  `@test` title set of `tests/hook-scripts-coverage.bats` into
  `tests/.hook-scripts-coverage-titles` and fails if the live file's title set
  drifts from the snapshot — i.e. any future PR that appends a new `@test` to
  this file (instead of its own `tests/hook-scripts-<scope>.bats`) fails
  `make ci` immediately.
- New `scripts/hook-scripts-coverage-tests-sync-hook.sh`: the local PostToolUse
  companion, filtering on edits to `tests/hook-scripts-coverage.bats` and
  delegating to the check script (same shape as
  `drift-detectors-tests-sync-hook.sh`). Wired into `.claude/settings.json`'s
  PostToolUse hook list.
- `Makefile`: new `hook-scripts-coverage-tests-check` (wired into `ci`) and
  `hook-scripts-coverage-tests-mark` (regenerate the snapshot after an
  intentional rename/edit) targets.
- `.github/workflows/ci.yml`: added the matching `drift` job step (kept in
  parity with `make ci` per `scripts/ci-parity-check.sh`, which caught the gap
  live during this PR's own `make ci` run before it was fixed).
- `tests/hook-scripts-coverage.bats`: header comment updated to record the
  freeze and point new hook coverage at `tests/hook-scripts-<scope>.bats`.
  No existing `@test` moved, renamed, or deleted.
- `tests/drift-frozen-monolith-checks.bats`: new `hook-scripts-coverage-tests-check`
  section (3 assertions), following the existing convention that this file
  holds coverage for every "-tests-check.sh" script that verifies a
  *different* frozen monolith (`securitycontext.bats`, `observability.bats`,
  `networkpolicy.bats`, and now `hook-scripts-coverage.bats`).
- `tests/hook-scripts-coverage-guard.bats`: new dedicated per-scope file
  covering the sync-hook itself (filtered-out case + currently-compliant
  case) — added as its own file rather than appended to the now-frozen
  monolith, per the guard's own rule.
- `tests/fixtures/hook-scripts-coverage-tests-check/{in-sync,drift}/`: golden
  fixture trees for the check script's own bats coverage.

## Scope discipline

Behavior-preserving: no existing `@test` was moved, renamed, or deleted — this
PR only freezes the file at its *current* content and adds the mechanical
guard against future growth. `make ci` stays green; the new gate does not
change any existing test's outcome. Splitting the existing 18 hook-script
sections into their own `tests/hook-scripts-<scope>.bats` files is a separate,
larger follow-up — not attempted here.

## PR

[#867](https://github.com/tooming/k8s-anywhere/pull/867)
