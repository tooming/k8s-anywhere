# Split ADR-governance-drift tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Fifth slice of the `tests/drift-detectors.bats` split-down
follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md),
[docs/done/2026-07-23-split-frozen-monolith-checks-bats.md](2026-07-23-split-frozen-monolith-checks-bats.md),
[docs/done/2026-07-23-split-yq-variant-checks-bats.md](2026-07-23-split-yq-variant-checks-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved three sections (`adr-followup-check`, `adr-chart-version-sync-check`,
`adr-image-pin-sync-check`; 13 `@test` blocks, 78 lines total) out of
`tests/drift-detectors.bats` into a new `tests/drift-adr-sync-checks.bats` —
a pure file move, no test logic changed. Grouped as one PR because all three
guard the same governance surface: `docs/decisions/` ADRs staying honest
about their own stated claims (no stale "Follow-up:" promise, no
self-tracking chart-version/image-pin note that has drifted from the live
gitops manifest it describes). `tests/drift-detectors.bats` shrinks from
458 to 380 lines. Regenerated `tests/.drift-detectors-titles` via
`make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-adr-sync-checks.bats` shows all 13 passing. No
script under test was touched. `make ci` stays green — same pre-existing,
environment-only `not ok` failures as every prior PR this run (this
sandbox's non-mikefarah `yq`), unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule. ~9 sections remain in the monolith —
further follow-up, not attempted here.

## PR

(filled in after PR creation)
