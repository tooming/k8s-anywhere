# Split CI-workflow-correctness tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Sixth slice of the `tests/drift-detectors.bats` split-down
follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md),
[docs/done/2026-07-23-split-frozen-monolith-checks-bats.md](2026-07-23-split-frozen-monolith-checks-bats.md),
[docs/done/2026-07-23-split-yq-variant-checks-bats.md](2026-07-23-split-yq-variant-checks-bats.md),
[docs/done/2026-07-23-split-adr-sync-checks-bats.md](2026-07-23-split-adr-sync-checks-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved three sections (`ci-parity-check`, the "push trigger scoped to main"
regression guard, and the "every job sets timeout-minutes" regression guard;
7 `@test` blocks, 65 lines total) out of `tests/drift-detectors.bats` into a
new `tests/drift-ci-workflow-checks.bats` — a pure file move, no test logic
changed. Grouped as one PR because all three guard the same surface:
`.github/workflows/ci.yml` staying correct and in parity with `make ci`.
`tests/drift-detectors.bats` shrinks from 380 to 308 lines. Regenerated
`tests/.drift-detectors-titles` via `make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-ci-workflow-checks.bats` shows all 7 passing.
No script under test was touched. `make ci` stays green — same
pre-existing, environment-only `not ok` failures as every prior PR this run
(this sandbox's non-mikefarah `yq`), unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule. ~6 sections remain in the monolith —
further follow-up, not attempted here.

## PR

(filled in after PR creation)
