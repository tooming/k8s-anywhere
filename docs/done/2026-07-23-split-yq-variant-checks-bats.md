# Split yq-variant-portability tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Fourth slice of the `tests/drift-detectors.bats` split-down
follow-up (prior slices:
[docs/done/2026-07-23-split-idle-issue-guard-bats.md](2026-07-23-split-idle-issue-guard-bats.md),
[docs/done/2026-07-23-split-mimir-readonly-root-bats.md](2026-07-23-split-mimir-readonly-root-bats.md),
[docs/done/2026-07-23-split-frozen-monolith-checks-bats.md](2026-07-23-split-frozen-monolith-checks-bats.md);
freeze that started this thread:
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md)).

## What changed

Moved three sections (`yq-raw-check`, `yq-variant-guard-check`, and the
single-test "yq variant portability guard"; 7 `@test` blocks, 57 lines
total) out of `tests/drift-detectors.bats` into a new
`tests/drift-yq-variant-checks.bats` — a pure file move, no test logic
changed. Grouped as one PR because all three guard the same class of bug:
mikefarah/yq (Go) and kislyuk/python-yq (jq wrapper) disagree on syntax
(bare `yq` calls, `-o=json`, `tag==""`), and a script/test written against
one variant silently produces false-negatives/false-positives on the other
— the exact bug class that already bit `mimir-readonly-root-check.sh`
(`chore/fix-mimir-ci-check-yq-compat`). `tests/drift-detectors.bats` shrinks
from 506 to 458 lines. Regenerated `tests/.drift-detectors-titles` via
`make drift-detectors-tests-mark`.

## Why this is safe

Pure move: every `@test` title/body/assertion is byte-identical in its new
location — `bats tests/drift-yq-variant-checks.bats` shows all 7 passing.
No script under test was touched. `make ci` stays green — same
pre-existing, environment-only `not ok` failures as every prior PR this run
(this sandbox's non-mikefarah `yq`), unrelated to this change.

## Scope discipline

Bounded to one coherent group of sections, per the janitor role's "small
enough to land green in one run" rule. ~13 sections remain in the monolith
— further follow-up, not attempted here.

## PR

[#684](https://github.com/tooming/k8s-anywhere/pull/684)
