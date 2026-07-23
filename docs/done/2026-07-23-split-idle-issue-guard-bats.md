# Split idle-issue-guard-check tests out of tests/drift-detectors.bats

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-
recurrence rule. Follow-up janitor fallback cleanup (`executor.prompt.md`
STEP 6b) to the same-run freeze in
[docs/done/2026-07-23-freeze-drift-detectors-bats.md](2026-07-23-freeze-drift-detectors-bats.md):
that PR froze `tests/drift-detectors.bats`'s `@test` set with a mechanical
guard but explicitly did not attempt to shrink the monolith itself (24+
unrelated drift-check sections, 662 lines), calling the split "a separate,
larger follow-up." This item is the first slice of that follow-up.

## What changed

Moved the entire `idle-issue-guard-check` section (7 `@test` blocks, 77
lines) out of `tests/drift-detectors.bats` into a new
`tests/drift-idle-issue-guard.bats` — a pure file move, no test logic
changed. `tests/drift-detectors.bats` shrinks from 685 to 613 lines (still
the largest drift-check file, since this was one section of 20+ remaining);
regenerated `tests/.drift-detectors-titles` via `make drift-detectors-tests-mark`
to reflect the intentional edit (the `drift-detectors-tests-check` gate added
in the prior PR would otherwise flag this as unauthorized drift — this is
exactly the "intentional rename/edit" escape hatch that gate documents).

Picked `idle-issue-guard-check` as the first section to extract because it
was fully self-contained (only depends on the file's own `setup()` for
`$REPO`, no cross-section fixtures) and is a natural, complete unit — the
same reasoning that made it a good first candidate when `securitycontext.bats`/
`observability.bats` were originally split per-scope.

## Why this is safe

Pure move: every `@test` title, body, and assertion is byte-identical in its
new location (verified: `bats tests/drift-idle-issue-guard.bats` — all 7
pass). No script under test (`scripts/idle-issue-guard-check.sh`) was
touched. Grepped the repo for any reference assuming the test file's
*location* (as opposed to the check script's own path, which is unrelated
and unchanged) — none found; every cross-reference
(`tests/action-needed-fallback.bats`'s header comment, ROADMAP.md,
CLAUDE.md, the routine prompts) only names `scripts/idle-issue-guard-check.sh`
itself.

`make ci` stays green — full local run shows the same pre-existing,
environment-only `not ok` failures from this sandbox's non-mikefarah `yq`
(unrelated to this change; verified in the prior cycle's PR #679 via
`git stash` that these fail identically on unmodified `main`).

## Scope discipline

Bounded to exactly one section move, per the janitor role's "small enough to
land green in one run" rule. Splitting the remaining ~20 sections is further
follow-up work, not attempted here — each is its own small, safe PR of the
same shape.

## PR

(filled in after PR creation)
