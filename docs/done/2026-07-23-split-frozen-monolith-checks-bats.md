# Split frozen-monolith-check tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Third slice of the `tests/drift-detectors.bats` split-down
follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved three sections (`securitycontext-tests-check`, `observability-tests-check`,
`networkpolicy-tests-check`; 9 `@test` blocks, 51 lines total) out of
`tests/drift-detectors.bats` into a new `tests/drift-frozen-monolith-checks.bats`
— a pure file move, no test logic changed. Grouped as one PR (rather than
three) because all three check scripts share one job — verifying a
*different* frozen monolith (`tests/securitycontext.bats`,
`tests/observability.bats`, `tests/networkpolicy.bats` respectively) hasn't
grown a new appended `@test` — so they form one coherent scope, not three
unrelated ones. `tests/drift-detectors.bats` shrinks from ~557 to 506 lines.
Regenerated `tests/.drift-detectors-titles` via `make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-frozen-monolith-checks.bats` shows all 9
passing. No script under test was touched. `make ci` stays green — same
pre-existing, environment-only `not ok` failures as every prior PR this run
(this sandbox's non-mikefarah `yq`), unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule. ~16 sections remain in the monolith
— further follow-up, not attempted here.

## PR

(filled in after PR creation)
