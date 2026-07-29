# Freeze tests/drift-detectors.bats — split-target mechanical guard

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Janitor fallback cleanup (`executor.prompt.md` STEP 6b) after
the "Now / next" lane came up fully gated on standing maintainer-confirmation
issues #631/#632/#633, and the planner/architect/upgrade-drafter/doc-drift-
author fallback lenses this run found no groomable issues, no new ADR-audit
triggers (one real finding already landed as PR #679, the TiDB version bump),
and no README/`docs/dependency-tree.md`/lab-UI drift.

## The footgun

`tests/drift-detectors.bats` had grown to 24+ unrelated `@test` sections
(`readme-check`, `lab-ui-check`, `roadmap-check`, `adr-followup-check`,
`adr-chart-version-sync-check`, `adr-image-pin-sync-check`,
`markdown-links-check`, `ci-parity-check`, two `ci.yml` structural checks,
`securitycontext-tests-check`, `observability-tests-check`,
`networkpolicy-tests-check`, `yq-raw-check`, `yq-variant-guard-check`,
`git-fixture-isolation-check`, `routines-author-check`, `routines-check`,
`helm-chart-pin-check`, `argocd-crd-ssa-check`, `rollouts-plugin-list-check`,
`mimir-readonly-root-check`, `idle-issue-guard-check`, and an O2 PSS
completeness gate) — every new, unrelated CI gate script appended its own
`@test` block to the same 662-line file. This is exactly the "shared monolith
multiple PRs append to" footgun CLAUDE.md's bugfix-recurrence rule calls out,
and the identical collision pattern that already got `tests/securitycontext.bats`
(#238 vs #239), `tests/observability.bats`, and `tests/networkpolicy.bats`
frozen with a mechanical guard — but `drift-detectors.bats`, the single
largest test file in the repo, had never received the same treatment.

## The fix

Mirrors the existing `securitycontext-tests-check` / `observability-tests-check`
pattern exactly:

- New `scripts/drift-detectors-tests-check.sh`: snapshots the sorted `@test`
  title set of `tests/drift-detectors.bats` into `tests/.drift-detectors-titles`
  and fails if the live file's title set drifts from the snapshot — i.e. any
  future PR that appends a new `@test` to this file (instead of its own
  `tests/drift-<scope>.bats`) fails `make ci` immediately.
- New `scripts/drift-detectors-tests-sync-hook.sh`: the local PostToolUse
  companion, filtering on edits to `tests/drift-detectors.bats` and delegating
  to the check script (same shape as `securitycontext-tests-sync-hook.sh`).
  **Not wired into `.claude/settings.json` in this PR** — an edit to that file
  was attempted and explicitly declined mid-session, so the hook script exists
  and is bats-tested standalone (`tests/hook-scripts-coverage.bats`) but is not
  yet registered as an active PostToolUse hook. The `make ci` gate (wired into
  both `Makefile`'s `ci:` target and `.github/workflows/ci.yml`'s `drift` job)
  is the actual enforcement mechanism and is fully active; the hook is only a
  local nudge on top of it. Wiring `.claude/settings.json` is left for a
  follow-up.
- `Makefile`: new `drift-detectors-tests-check` (wired into `ci`) and
  `drift-detectors-tests-mark` (regenerate the snapshot after an intentional
  rename/edit) targets, mirroring `securitycontext-tests-check`/`-mark`.
- `.github/workflows/ci.yml`: added the matching `drift` job step (kept in
  parity with `make ci` per `scripts/ci-parity-check.sh`, which caught the gap
  live during this PR's own `make ci` run before it was fixed).
- `tests/drift-detectors.bats`: added a `drift-detectors-tests-check` section
  (3 assertions, same shape as the `securitycontext-tests-check`/
  `observability-tests-check` sections already inside it) documenting the
  freeze, then generated `tests/.drift-detectors-titles` from the final state
  — so the guard's own test coverage is part of the frozen baseline, exactly
  like `securitycontext-tests-check`'s own tests live inside the monolith it
  guards.
- `tests/fixtures/drift-detectors-tests-check/{in-sync,drift}/`: golden
  fixture trees for the check script's own bats coverage.
- `tests/hook-scripts-coverage.bats`: two new assertions for the sync-hook
  script (filtered-out case + currently-compliant case), plus the file's
  header comment updated to list it.

## Scope discipline

Behavior-preserving: no existing `@test` was moved, renamed, or deleted — this
PR only freezes the file at its *current* content (plus the new guard's own
tests, added before the snapshot was taken) and adds the mechanical guard
against future growth. Splitting the existing 24 sections into their own
`tests/drift-<scope>.bats` files is a separate, larger follow-up (would push
this PR well past the ~400 changed-line budget, WAYS-OF-WORKING.md §3) — not
attempted here. `make ci` stays green; the new gate does not change any
existing test's outcome.

## PR

[#680](https://github.com/tooming/k8s-anywhere/pull/680)
