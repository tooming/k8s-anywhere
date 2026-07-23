# Split mimir-readonly-root-check tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Second slice of the `tests/drift-detectors.bats` split-down
follow-up (first slice:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved the self-contained `mimir-readonly-root-check` section (7 `@test`
blocks, 56 lines) out of `tests/drift-detectors.bats` into a new
`tests/drift-mimir-readonly-root.bats` — a pure file move, no test logic
changed (including its `$FIX` fixture-dir reference, which resolves
identically from the new file since fixtures live under the shared
`tests/fixtures/` tree, not relative to the test file that references them).
`tests/drift-detectors.bats` shrinks from 613 to ~557 lines. Regenerated
`tests/.drift-detectors-titles` via `make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-mimir-readonly-root.bats` shows all 7 passing.
No script under test (`scripts/mimir-readonly-root-check.sh`) was touched.
`make ci` stays green — same pre-existing, environment-only `not ok`
failures as every prior PR this run (this sandbox's non-mikefarah `yq`),
unrelated to this change.

## Scope discipline

Bounded to exactly one section move, per the janitor role's "small enough to
land green in one run" rule. ~19 sections remain in the monolith — further
follow-up, not attempted here.

## PR

(filled in after PR creation)
