# Fix two stale gap notes in ROADMAP.md's "Cross-cutting hardening & quality" section

JANITOR-fallback cleanup (executor STEP 6b, reached after PLANNER, ARCHITECT,
UPGRADE-DRAFTER, DOC-DRIFT-AUTHOR, and TRIAGER all came up empty this cycle —
"Now / next" stayed fully gated on issue #633 and the two sequentially-blocked
GitLab→Forgejo migration items, and this run's own architect-fallback cycle
already refreshed this week's industry digest earlier).

## What was found

`ROADMAP.md`'s "Cross-cutting hardening & quality" section carried two
prose notes describing gaps as still-open that were, in fact, both fully
resolved long ago — a stale-doc-reference bug, the same class of drift this
repo's own JANITOR fallback exists to catch:

1. **"O4 gap (surfaced 2026-06-25)"** — said the CI step proving an unsigned
   image gets rejected by Kyverno "does not exist yet." Verified against the
   real repo state: it does exist. Both the `verifyImages` Enforce flip
   (`auto/cosign-enforce-flip`, PR #1223) and the `verify-image-rejection` CI
   job (`auto/o4-ci-rejection-gate`, PR #1224) merged **2026-08-18** — nearly
   three weeks before this cleanup — and are already recorded as `[x]` items
   elsewhere in this same file, plus in the "Now / next" section's own top
   status note ("O4 ... landed both of its measurement criteria 2026-08-18").
   The stale note was simply never removed once the gap it described closed.

2. **"Two upgrade-drafter major-bump findings parked 2026-07-24 (issues #704,
   #705)"** — said both needed "an architect go/no-go call, not a mechanical
   bump." Verified directly against GitHub: both issues were closed the
   **same day** they were filed (2026-07-24), once groomed into ROADMAP
   items. #704 (kube-state-metrics `7.8.1`→`8.0.0`) shipped via RFC #707/
   PR #710. #705 (`apache/kafka` `3.9.2`→`4.3.1`) was decided **Hold** via
   RFC #708. Both outcomes are already recorded as `[x]`/`~~🟡~~` items
   elsewhere in this same file. The note describing them as still awaiting a
   decision was over five weeks stale.

Both notes risked misleading a future planner/architect cycle into
re-investigating already-closed questions, or overstating how much open work
remains in this section — the opposite of ADR-0004's "never present
non-current state as current" spirit applied to internal planning docs.

## What was fixed

Rewrote both notes in place to state the real, current, resolved status with
a citation trail back to the PRs/RFCs and the `[x]` items already recording
each resolution — mirroring how every other note in this section already
documents its own grooming history (e.g. the RFC #205/#206/#214/#215/#229/
#230 grooming notes immediately above them). No ROADMAP *items* (checkbox
lines) were touched — only the prose status notes above them.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose correction
in ROADMAP.md's own commentary, no code/manifest/test touched. Every claim
verified against a primary source in this session: the real merged-PR trail
already in this file (lines ~1553, ~2222, ~2227/2278/2295), the "Now / next"
top status note, and GitHub's own issue records for #704/#705 (state, close
date, close-comment grooming trail).

## PR

(backfilled after PR creation)
