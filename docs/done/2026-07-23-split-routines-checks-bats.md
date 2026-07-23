# Split routines-governance tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Seventh slice of the `tests/drift-detectors.bats` split-down
follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md),
[docs/done/2026-07-23-split-frozen-monolith-checks-bats.md](2026-07-23-split-frozen-monolith-checks-bats.md),
[docs/done/2026-07-23-split-yq-variant-checks-bats.md](2026-07-23-split-yq-variant-checks-bats.md),
[docs/done/2026-07-23-split-adr-sync-checks-bats.md](2026-07-23-split-adr-sync-checks-bats.md),
[docs/done/2026-07-23-split-ci-workflow-checks-bats.md](2026-07-23-split-ci-workflow-checks-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved two sections (`routines-author-check`, `routines-check`; 7 `@test`
blocks, 65 lines total) out of `tests/drift-detectors.bats` into a new
`tests/drift-routines-checks.bats` — a pure file move, no test logic
changed. Grouped as one PR because both guard `routines/routines.yaml`
staying honest and correctly tracked (who may edit it, and that drift on it
is actually detected). `tests/drift-detectors.bats` shrinks from 308 to 243
lines. Regenerated `tests/.drift-detectors-titles` via
`make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-routines-checks.bats` shows all 7 passing. No
script under test was touched (and this branch does not edit
`routines/routines.yaml` itself, so `routines-author-check`'s own
"passes on the real repo" assertion still holds). `make ci` stays green —
same pre-existing, environment-only `not ok` failures as every prior PR
this run (this sandbox's non-mikefarah `yq`), unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule. ~4 sections remain in the monolith
(`helm-chart-pin-check`, `argocd-crd-ssa-check`, `rollouts-plugin-list-check`,
the O2 PSS completeness gate) plus the guard's own section — the monolith is
now 243 lines, down from 662 at the start of this thread (63% reduction).

## PR

(filled in after PR creation)
