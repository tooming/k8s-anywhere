# Detect and prune orphaned agent branches with no open PR

JANITOR-fallback bounded cleanup (category 1: "a footgun that already bit
us"), reached via `executor.prompt.md` STEP 6b after PLANNER, ARCHITECT,
UPGRADE-DRAFTER, DOC-DRIFT-AUTHOR, and TRIAGER all found nothing this cycle
(a full recon sweep confirmed: CHARTER-vs-repo gap analysis clean, only 2
open issues already fully labeled, zero un-RFC'd 🟡 items, six of seven
spot-checked currency pins already latest-stable with the seventh
deliberately held per ADR-0008, and every doc-drift gate green).

## The footgun

`scripts/prune-stale-branches.sh` (run by the `SessionStart` hook every
session) classified remote agent branches into two safe-to-delete buckets —
MERGED (tip is an ancestor of main) and UNRELATED (no common ancestor with
main) — and kept everything else unconditionally, reasoning "shares history
with main + has unique commits = a plausible open PR". That heuristic has a
real blind spot: a branch pushed by a producing routine whose *own PR
creation step then failed or was skipped* satisfies "shares history + has
unique commits" forever, with no open PR ever backing it, and the script had
no way to tell the two cases apart.

Found live during this session's STEP 1 orient: two such orphans, discovered
via the `SessionStart` hook's own "Active (kept)" branch list combined with a
`gh`-equivalent open-PR check (this repo's own MCP GitHub tools, since `gh`
CLI isn't available in this remote session):

- `auto/pr-creation-diagnostic-test` — pushed 2026-07-24, explicitly titled
  "diagnostic commit for PR-creation 500 investigation (to be discarded)".
- `auto/action-needed-cycle13-doc-precision-lane-slowing` — pushed
  2026-08-07, a real `[Action needed]` record whose PR was apparently never
  opened (same failure class the diagnostic branch's own name documents).

Both sat on the remote for weeks, silently invisible to every session's
branch-hygiene pass, because the script's own design comment declared
"ALWAYS kept — never deleted" for exactly this shape.

## The fix

Added a third, best-effort classification — ORPHANED — gated on two safety
properties so it can never misfire against real in-flight work:

1. **Needs a live open-PR check.** Uses `gh pr list --state open --search
   "head:<prefix>/ ..."` across every agent branch prefix (same pattern as
   `stale-prs-check.sh`), and is skipped entirely — zero behavior change —
   when `gh` is unavailable/unauthenticated. "gh has nothing to say" is
   never treated as "no open PR exists".
2. **Time-gated (`ORPHAN_AGE_S`, default 24h).** A branch pushed moments
   before its PR is created (the normal gap in every producing routine's own
   STEP 6) is never caught — only a branch confirmed to have no open PR
   *and* old enough that the normal creation window has long passed.

Also de-duplicated the branch-prefix list (previously spelled out twice,
once in the discovery regex comment and once inline in the `grep -E`
pattern — the exact kind of drift that let `plan/upgrade/sync/digest` go
unmatched until PR #936's fix) into one `PREFIXES` array shared by both the
discovery regex and the new open-PR search.

`tests/prune-stale-branches.bats` gained four new cases: the orphan class
fires past the age gate with no open PR; it does NOT fire within the age
gate (safety net 1); it does NOT fire when `gh` confirms a real open PR
exists, even past the age gate (safety net 2); and it is skipped entirely
end-to-end when `gh` is unavailable (git-only fallback unchanged). All 10
tests in the file pass, and the full `make ci` (bats, drift, lint, kustomize,
terraform, manifests) is green.

## Applying it

`gh` isn't available in this remote session, so the new gh-backed path in
the script itself couldn't be exercised live here — but the same live-PR
fact it depends on was already independently verified via this repo's
GitHub MCP tools (`list_pull_requests --state open` returned zero results
repo-wide). Both confirmed-orphaned branches above were deleted directly
(`git push origin --delete`) as the direct, manually-verified application of
this fix; a future session with `gh` available will have the script itself
catch any new occurrence.

## PR

https://github.com/tooming/k8s-anywhere/pull/1244
