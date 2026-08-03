# Deduplicate the `yqs()` scalar-read helper across scripts/*.sh

Autonomous janitor-role cleanup (executor STEP 6b fallback chain, 2026-08-03):
`scripts/adr-chart-version-sync-check.sh` and
`scripts/context-doc-version-sync-check.sh` each carried their own
byte-identical copy of a `yqs()` helper — a yq-variant-robust scalar reader
(mikefarah yq prints scalars raw, python-yq JSON-quotes them; `yqs()`
normalises both to raw output, mirroring `tests/lib/yq.bash`'s helper for
bats tests). Found during a duplication sweep after the ROADMAP "Now / next"
lane came up fully gated (issues #631/#633, no maintainer confirmation yet)
and the planner/architect/upgrade-drafter fallback tiers had already each
produced their own deliverable or genuine no-op this run.

Two near-identical copies of the same 6-line function is exactly the kind of
copy-paste that silently drifts the moment one copy gets a fix the other
doesn't — the duplication class CLAUDE.md's bugfix-recurrence rule calls out,
applied here proactively (before a divergence bug, not after one).

## What changed

- New `scripts/lib/yq.sh` — the one shared copy of `yqs()`, sourced (not
  executed), documented with the same rationale as `tests/lib/yq.bash`.
- `scripts/adr-chart-version-sync-check.sh` and
  `scripts/context-doc-version-sync-check.sh` — removed their own inline
  `yqs()` definitions, now `source .../lib/yq.sh` instead. Behavior
  unchanged (byte-identical function body, just no longer duplicated).
- New `scripts/yqs-lib-check.sh` (+ `make yqs-lib-check`, wired into `make ci`
  and `.github/workflows/ci.yml`'s `drift` job) — a recurrence guard mirroring
  the existing `yq-variant-guard-check.sh` pattern: fails if any
  `scripts/*.sh` file defines its own local `yqs()` instead of sourcing the
  shared copy, so this exact duplication can't quietly reappear.
- New `scripts/yqs-lib-sync-hook.sh` (wired into `.claude/settings.json`'s
  `PostToolUse` hooks) — the local, immediate-feedback companion to the CI
  gate above.
- New bats coverage: `tests/lib-yq.bats` (direct unit tests for `yqs()`'s
  quote-stripping / exit-code / stderr-swallowing behavior),
  `tests/drift-yqs-lib.bats` (the new drift guard's own tests, fixture-based,
  per the `tests/drift-<scope>.bats` convention — `tests/drift-detectors.bats`
  is frozen), `tests/hook-scripts-yqs-lib.bats` (the new sync hook's coverage,
  per the `tests/hook-scripts-<scope>.bats` convention —
  `tests/hook-scripts-coverage.bats` is frozen), plus two small fixture
  scripts under `tests/fixtures/yqs-lib-check/{in-sync,drift}/`.

## What didn't change

Behavior-preserving only: the `yqs()` function body is byte-for-byte
identical to what both scripts carried before, so `adr-chart-version-sync-check`
and `context-doc-version-sync-check`'s actual pass/fail behavior against the
live repo is unchanged (both still pass — verified directly, not assumed).
No topology change, so no README/`docs/dependency-tree.md` update.

`make ci` must pass.

## PR

[#956](https://github.com/tooming/k8s-anywhere/pull/956)
