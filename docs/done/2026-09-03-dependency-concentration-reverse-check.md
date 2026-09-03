# dependency-concentration-sync-check: close the "reverse direction" gap + fix a stale comment

`scripts/dependency-concentration-sync-check.sh`'s own header comment named two
open gaps when it first landed (#1379, 2026-09-02): (1) it doesn't check the
reverse direction — a `docs/dependency-concentration.md` group whose stated
data has drifted from the register; (2) `docs/dependency-exit-runbooks.md`'s
own downstream sync to `concentration.md`. A coverage sweep this run found gap
(2) was actually already closed the same day by a sibling script,
`scripts/dependency-exit-runbooks-sync-check.sh` (#1380) — but the comment
here was never updated to say so, leaving a stale claim that an already-closed
gap was still open. Gap (1) was genuinely still open.

## What changed

- **Fixed the stale comment**: no longer claims the exit-runbooks sync gap is
  open; explains it was closed by #1380 the same day #1379 landed.
- **Closed the reverse-direction gap**: added a second check pass that parses
  every `` **`github.com/ORG` — N tools** `` group header in
  `dependency-concentration.md` and verifies, against the same register-row
  count the forward check already computes:
  - the org still backs 2+ rows in `dependency-register.md` (catches a stale
    entry naming a group that no longer meets the concentration threshold —
    e.g. rows removed or re-attributed to a different org since the entry was
    written);
  - the stated "N tools" count still matches the register's real row count
    (catches a count that drifted either up or down without the concentration
    entry being updated).
- New bats coverage: two new fixtures
  (`tests/fixtures/dependency-concentration-sync-check/{reverse-stale,reverse-mismatch}/`)
  plus three new test cases in `tests/dependency-concentration-sync-check.bats`
  exercising both new failure modes and the passing case. Verified by hand
  (bats isn't installed in this clusterless environment) against both new
  fixtures and the two pre-existing ones (`in-sync`, `drift`) — all four
  produce the expected exit code and output before wiring the bats assertions.

## Why this is real (not manufactured) JANITOR-fallback work

Found via this run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) after ROADMAP's "Now / next" lane was re-confirmed fully gated (the
three remaining unchecked items are all still blocked — two on the
GitLab→Forgejo bootstrap-flow cutover not yet verified end-to-end, one on
maintainer confirmation via issue #633) and PLANNER/ARCHITECT both came up
empty (zero ungroomed intake/rfc issues, zero un-RFC'd 🟡 items). This is an
honest, previously-undetected gap in the repo's own mechanical drift tooling —
exactly the "nothing catches it" failure mode this script exists to close for
the register itself, just found one level up in the tooling that watches the
register.

No `gitops/` or `docs/decisions/` change. `make ci` passes green.

## PR

(filled in after PR creation)
