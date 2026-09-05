# ROADMAP.md legacy `[x]` item trim — batch 7

Continuing the pilot batch, batch 2, batch 3, batch 4, batch 5, and batch 6
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md)).

## What was done

Batch 6 widened the candidate lens to "items with a `docs/done/` mention
already present, in case any of those still carry a lot of inline
duplication alongside the pointer" — this batch acted on that lens. Found
and trimmed 4 items whose inline ROADMAP text already had a
`docs/done/` pointer but still duplicated most or all of that file's
content below it (the older full-spec text left over from before the
short-pointer convention was applied to that item), each re-verified
against its real `docs/done/` mirror and real merged-PR link before
touching the ROADMAP text:

- **`kube-state-metrics` chart major bump `7.8.1` → `8.0.0`** →
  [docs/done/2026-07-24-ksm-chart-8-0-0.md](2026-07-24-ksm-chart-8-0-0.md)
  (PR #710, confirmed `merged: true`) — had no pointer at all yet; added
  the short-pointer form directly.
- **Third-party dependency concentration-risk rollup (DORA Q16)** →
  [docs/done/2026-08-12-dependency-concentration-rollup.md](2026-08-12-dependency-concentration-rollup.md)
  (PR #1163, confirmed `merged: true`) — same as above, no pointer yet.
- **Valkey `8.1.9-alpine` → `8.1.10-alpine` security bump** →
  [docs/done/2026-09-01-valkey-8-1-10-security-bump.md](2026-09-01-valkey-8-1-10-security-bump.md)
  (PR #1361, confirmed `merged: true`) — **this one already had the
  pointer**, but ~85 lines of the original full spec (verification detail,
  the "not yet groundable" Docker Hub check, the four touch points) were
  still duplicated below it, word-for-word mirrored in the linked file.
- **GitHub→Forgejo pull-based, fast-forward-only sync workflow** →
  [docs/done/2026-08-25-forgejo-github-sync-workflow.md](2026-08-25-forgejo-github-sync-workflow.md)
  (PR #1347, confirmed `merged: true`) — also already had the pointer, but
  additionally still carried a **live, unresolved `PR TBD` placeholder**
  in its parenthetical (`(RFC #1340; PR TBD.)`) — a real drift bug, same
  class `scripts/docs-done-pr-link-check.sh` guards for in `docs/done/`
  files, just in ROADMAP.md's own inline item text instead (a location
  that check doesn't scan). Fixed by resolving to the real PR number
  found via GitHub search, alongside removing the ~17 duplicated lines of
  "Correction found live during implementation" prose already mirrored in
  the linked file.

Grepped the whole file for `PR TBD`/`PR #TBD`/`pull/TBD`/`(see GitHub)`
afterward to confirm no other live placeholder remains (the three other
hits are historical narrative inside already-completed batch write-ups,
not live placeholders).

No information lost in any of the four — the full detail already lives in
each linked `docs/done/` file, confirmed equivalent by reading all four
before editing.

## Why this is in scope for a JANITOR cycle

`executor.prompt.md`'s STEP 6b fallback chain was walked in full this
cycle: the three "Now / next" items remain gated (issues #633/#1229 both
re-checked, no new confirmation since 2026-08-25); PLANNER found zero
ungroomed intake, zero `docs/roadmap/incoming/` files, and zero un-RFC'd
🟡 items anywhere in ROADMAP.md; ARCHITECT has nothing to RFC for the same
reason; a fresh UPGRADE-DRAFTER currency pass (Harbor's helm-chart tags,
TiDB Operator's `1.6.x` line, `scripts/dependency-maintenance-check.sh`'s
full 34-repo maintenance-activity sweep) found every checked source
already at its newest available/in-scope version; DOC-DRIFT-AUTHOR found
zero drift (`make ci` clean); TRIAGER found all 3 open issues already
fully labeled. JANITOR is the first fallback role to yield real work:
continuing the established legacy-item-trim cleanup (batches 1–6) with a
new, narrower lens — and along the way, fixing the one live `PR TBD`
placeholder is exactly CLAUDE.md's "fix + mechanical guard" bugfix
pattern applied at the smallest possible scope: the guard here **is** the
fix itself, since trimming an item to the short-pointer form removes the
only place a stale PR reference could live in that item going forward
(the linked `docs/done/` file's own `## PR` section is already guarded by
`scripts/docs-done-pr-link-check.sh`). A repo-wide guard scanning every
one of ROADMAP's ~150 still-untrimmed legacy items for the same class is
intentionally out of scope for one bounded cycle, matching how batches
1–6 operated — future cycles continue the same systematic trim.

## Result

`ROADMAP.md`: 6921 → 6759 lines (162 lines saved from 4 items — the
largest single-batch saving yet, since two of the four had large
duplicated bodies alongside an already-present pointer rather than no
pointer at all). `make ci` passes green (lint, README/lab-UI/roadmap
drift checks, ADR chart/image-pin sync, dependency-register sync, every
`docs/done/` file's PR-link check — all clean; `bats`/`kustomize`/
`terraform` aren't installed in this remote clusterless session, so those
steps no-op locally as usual — the real backstop is GitHub Actions'
`ci.yml`, kept in parity per `CLAUDE.md`).

No `gitops/` change.

## PR

(filled in after PR creation)
