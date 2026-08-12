# [Action needed] Now/next still gated; repo-wide GitHub-issue-status cross-check clean

**Date:** 2026-08-12
**Cycle:** 9th cycle this run (after PR #1162 through #1169 — see prior cycles'
records in this same directory for the full chain)

## What's blocked

The "Now / next" lane holds the same six unchecked items as every prior cycle this
run, unchanged (three sequential Forgejo-migration items; `verifyImages` Enforce-flip
+ O4 CI gate on unconfirmed issue [#631](https://github.com/tooming/k8s-anywhere/issues/631);
capstone `Deployment` removal on unconfirmed issue
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — both re-checked this
cycle, `updated_at`/comment count unchanged since 2026-08-11).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER / ARCHITECT / UPGRADE-DRAFTER / DOC-DRIFT-AUTHOR / TRIAGER**: no new
  findings beyond the preceding eight cycles this run.
- **JANITOR**: direct follow-through on the previous cycle's find (PR #1169 fixed a
  stale "issue #1034 still open" claim carried in two docs). This cycle audited every
  *other* GitHub issue number cited by a real `github.com/.../issues/NNN` URL across
  `docs/*.md` and `ROADMAP.md` for the same failure mode — checking each cited
  issue's actual live state rather than trusting the doc's own prose. Only four
  distinct issue numbers are referenced this way in the whole repo: **#631** (open,
  correctly described as open everywhere it's cited), **#633** (open, same), **#1034**
  (closed — already fixed last cycle, PR #1169), and **#215** (closed, cited in
  `docs/DR.md`'s O6/`make capstone-demo` section as the RFC that spec'd the feature —
  correctly described as an implemented, closed RFC, not claimed open anywhere). No
  further staleness found.

## What would unblock the standing gates

Unchanged from every prior cycle's note: both #631 and #633 need a live-cluster
session with real host headroom to complete a full pipeline run — see the new
"Harbor signed-image-pipeline verification" runbook in `docs/DR.md` (added this run,
PR #1168, corrected PR #1169) for the consolidated checklist.

This is a real, honest cycle outcome, not an idle declaration — per STEP 8, the run
continues past this point to the next cycle.
