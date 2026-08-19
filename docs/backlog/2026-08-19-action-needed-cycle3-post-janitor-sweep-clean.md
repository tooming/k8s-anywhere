# [Action needed] Now/next still gated; post-JANITOR sweep, third cycle this run

**Date:** 2026-08-19
**Cycle:** 3rd cycle this run

## What was shipped this run so far (for context)

1. `auto/action-needed-cycle1-fallback-chain-exhausted` (PR #1243) — cycle 1's
   honest record after the full STEP 6b fallback chain came up empty.
2. `chore/prune-stale-branches-orphan-class` (PR #1244) — cycle 2's JANITOR
   fallback: found and fixed a real footgun (`scripts/prune-stale-branches.sh`
   kept any branch sharing history with `main` forever, with no way to detect
   a branch whose own PR-creation step had failed or been skipped after the
   push — found live via two such orphans, `auto/pr-creation-diagnostic-test`
   and `auto/action-needed-cycle13-doc-precision-lane-slowing`, both weeks
   old with zero open PR ever backing them). Added a best-effort, time-gated
   ORPHANED class + 4 new bats tests; full `make ci` green.
3. `chore/correct-orphan-branch-deletion-claim` (PR #1245) — a same-run
   self-correction: PR #1244's `docs/done/` record claimed the two orphaned
   branches were deleted, but that `git push origin --delete` attempt (run
   after #1244 merged) actually failed with HTTP 403 (this session's git
   push access has no branch-delete rights). Caught via direct verification
   (`git ls-remote`) rather than left as a false "done" claim (ADR-0004).
   Both branches remain on the remote, undeleted, still un-covered by this
   run's own git-push permissions — a future session with `gh` and delete
   rights will have PR #1244's fix catch them automatically.

## What's blocked

Unchanged from cycle 1: the "Now / next" lane holds the same three items —
the two GitLab→Forgejo migration items remain un-picked-up per their own
investigation notes (SSH deploy-key vs. HTTPS+PAT auth-model finding), and
the legacy capstone `Deployment` removal remains gated on issue #633,
re-checked this cycle — `updated_at` still 2026-08-17T18:50:01Z, no new
confirmation comment.

## What was tried this cycle (a different lens from cycle 1)

Rather than repeat cycle 1's full 6-lane fallback sweep verbatim, this cycle
tried two angles cycle 1 didn't:

- **ADR follow-up-promise sweep.** Grepped every ADR for phrases suggesting
  an untracked deferred item ("needs its own", "follow-up item", "worth a
  future", etc.). Found 4 hits (ADR-0006, ADR-0016, ADR-0028, ADR-0029).
  Read each in context: ADR-0006's is a versioned Grafana bump deferral
  already covered by the standard currency-hold pattern; ADR-0016's is a
  hypothetical ("if any future ROADMAP item adds..."), not a promise;
  ADR-0028's HTTPS-listener follow-up and ADR-0029's cert-manager-webhook-
  wiring follow-up are both explicitly marked "shipped" in their own ADR
  text. This entire class is already mechanically guarded by
  `adr-followup-check.sh` (confirmed passing in this cycle's `make ci` run)
  — nothing new to find here, the gate already does what this manual sweep
  would.
- **PR-creation-500 root cause.** The diagnostic branch PR #1244 found
  (`auto/pr-creation-diagnostic-test`) references investigating a "PR-
  creation 500 error" from 2026-07-24. Grepped `docs/` for any record of
  root-causing or resolving that specific failure — found none beyond this
  run's own new doc. Not pursued further: this run created 3 PRs via the
  GitHub MCP tools with zero creation failures, so whatever caused that
  historical 500 (likely specific to a different session's tooling/
  transport at the time) shows no live symptom to investigate against —
  chasing a 26-day-old, non-reproducing error with no new evidence would be
  speculation, not verifiable work (ADR-0004).

Also re-ran the open-PR/open-issue checks: 0 open PRs, same 2 open issues
(#633, #1229) as cycle 1, both already correctly labeled.

## Why this is the honest deliverable

This cycle already has two real, shipped deliverables (PR #1244's bugfix +
PR #1245's correction) — this record closes out the cycle rather than
manufacturing a third distinct change once the two fresh angles above came
up empty. Recording honestly per ROADMAP rule #9 and `executor.prompt.md`
STEP 6b/STEP 8. Not a stopping point — the run continues from STEP 1.
