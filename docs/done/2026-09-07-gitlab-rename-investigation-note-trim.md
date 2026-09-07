# Move the GitLab→Forgejo rename item's inline "Update" prose out of ROADMAP.md, per its own investigation-note discipline rule

JANITOR-fallback cleanup (executor STEP 6b), a direct follow-up to this same
run's earlier `chore/roadmap-cross-cutting-stale-notes-cleanup` cycle — a
second pass over ROADMAP.md hygiene after PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER all remained empty (nothing external changed in the
few minutes since that cycle's own checks) and the fully-gated "Now / next"
lane was unchanged.

## What was found

ROADMAP.md's own "Investigation-note discipline" rule (added 2026-08-25,
also a JANITOR-fallback cleanup) states: "When picking up an item and finding
it still blocked, write the full investigation ... to
`docs/roadmap/investigations/` ... instead of appending it inline here. Keep
only a short 'Investigated YYYY-MM-DD — <one-line reason still blocked>, full
findings: <link>' pointer in the item body." This rule exists specifically to
control ROADMAP.md's size (>500 KB as of 2026-08-25, exceeding what standard
tooling can load in a single pass).

The "Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh`" item (still
gated, unchanged this cycle) violated its own file's rule: two dated "Update
2026-09-06" paragraphs (from live-cluster sessions closing adjacent gaps —
the missing `repo-forgejo-gitops` Secret bug, and GitLab left running
post-bootstrap burning ~3 GiB) had been appended directly inline in
ROADMAP.md instead of going to the item's own
`docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md` file,
which — checked directly — contained neither update.

## What was fixed

- Moved both "Update 2026-09-06" paragraphs into
  `docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md` as dated
  `## Update` sections, plus a closing "Status as of 2026-09-06" summary
  noting the underlying rename/decommission question is still unresolved by
  either update.
- Replaced the ~35-line inline block in ROADMAP.md with a ~9-line pointer
  matching the discipline rule's own prescribed shape ("Investigated
  YYYY-MM-DD ... re-confirmed still blocked YYYY-MM-DD ... full findings:
  <link>"), preserving the one-line reason and the two adjacent-gap
  mentions so a future reader doesn't lose that context without following
  the link.
- No change to the item's readiness tag, checkbox state, or actual
  recommendation — this is a pure relocation of prose, not a re-evaluation
  of the blocker itself (still genuinely blocked, per the investigation
  file's own unchanged Recommendation section).

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a docs-only relocation,
no code/manifest/test touched. Verified before editing that the investigation
file did not already contain either 2026-09-06 update (`grep -c 2026-09-06`
on the file returned `0`), so nothing was duplicated.

## PR

(backfilled after PR creation)
