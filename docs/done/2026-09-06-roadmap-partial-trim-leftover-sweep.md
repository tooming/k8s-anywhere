# ROADMAP.md partial-trim leftover sweep — 22 items

JANITOR-fallback cleanup (STEP 6b), continuing the
[batch 15](2026-09-05-roadmap-legacy-item-trim-batch15.md) through
[batch 30](2026-09-06-roadmap-legacy-item-trim-batch30.md) chain, but a
**different bug class** than those batches' "still fully verbose inline"
items.

## Why in scope

Re-walked the STEP 6b fallback chain fresh after batch 30 merged (PR #1444):
issues #633 and #1229 both remain open/unconfirmed, so the "Now / next"
ROADMAP lane is still fully gated. No open PLANNER/ARCHITECT/DOC-DRIFT-AUTHOR/
TRIAGER work was found, and no other open PRs existed this cycle (PR #1441,
the sibling KRO upgrade, merged during batch 30's cycle).

Continuing the JANITOR legacy-item-trim scan for batch 31, the standard
`awk` presence-only scan (checks only whether the phrase "full verification
writeup" appears *anywhere* in a block) returned false negatives for a large
class of items where that exact phrase is split across a line-wrap
(`...batch 6** — full verification\n  writeup:` — "verification" and
"writeup" land on different physical lines). A corrected scan
(whitespace-normalized before matching) found a **much larger problem than a
single missed candidate**: 22 items across the file already carry the
short-pointer format from an earlier pass, but retain the **original verbose
inline prose directly below the pointer**, undeleted — the same
partial-trim-leftover bug first caught in batch 28 and batch 30, but at far
greater scale (a whole run's worth of 2026-09-02/03/04 JANITOR-cycle items
never had their trailing prose removed when the pointer was added).

## What this batch fixed

For each of the 22 items below: verified the block's own `docs/done/*.md`
mirror link and branch citation were already correct, verified the cited PR
(where cited) or looked one up (`search_pull_requests`) and independently
confirmed `merged: true` via the GitHub API (ADR-0004 — direct API calls,
not trusting any prior claim), then deleted the leftover trailing prose,
keeping only the standard 4-line pointer (title/link/branch+PR).

1. **PSA baseline + NetworkPolicy — `lab-demo` namespace** — a **self-caught
   miss from batch 30 itself**: batch 30's own PR body claimed this item was
   trimmed, but the actual `Edit` call was never made (verified PR #256, then
   never applied) — caught and fixed in this batch. PR #256.
2. **ArgoCD full GHSA sweep** — PR #1393.
3. **Cilium: Critical advisory GHSA-3fcv-jvfp-m4q9** — PR #1392.
4. **Envoy Gateway full GHSA sweep** — PR #1391.
5. **Refresh `docs/dora-metrics.md`** — PR #1390.
6. **De-duplicate `dependency-register-check.sh`'s row-parsing logic** — PR
   #1389.
7. **Bump Kyverno chart `3.8.2` → `3.9.0`** — PR #1388.
8. **Bump k3s `v1.36.3+k3s1` → `v1.36.4+k3s1`** — PR #1387.
9. **Bump Aiven Inkless broker `4.2.1-0.46` → `4.2.1-0.47`** — PR #1386.
10. **Bump Grafana image tag `13.0.7` → `13.0.8`** — PR #1384.
11. **Bump Loki image tag `3.7.6` → `3.7.7`** — PR #1383.
12. **Extend `docs/dependency-exit-runbooks.md` to the remaining seven
    single-tool rows** — PR #1382.
13. **KEDA + Velero full GHSA sweep** — PR #1396.
14. **cert-manager full GHSA sweep** — PR #1395.
15. **Author ADR-0037 — HashiCorp Vault (retroactive record)** — PR #1394.
16. **ROADMAP.md legacy `[x]` item trim — batch 6** — PR #1415.
17. **ROADMAP.md legacy `[x]` item trim — batch 5** — PR #1414.
18. **ROADMAP.md legacy `[x]` item trim — batch 4** — PR #1413.
19. **ROADMAP.md legacy `[x]` item trim — batch 3** — PR #1412.
20. **docs/done/ PR-link integrity fix — 80 files** — PR #1411.
21. **ROADMAP.md legacy `[x]` item trim — batch 2** — PR #1410.
22. **ROADMAP.md legacy `[x]` item trim — pilot batch (RFC #377 Oracle
    items)** — PR #1409.
23. **Oldest dependency-register rows re-swept** — PR #1407.
24. **Pyroscope currency re-check** — PR #1406.
25. **Issue #1229 wrongly closed alongside PR #1403 — reopened** — PR #1404.
26. **Restore the silently-dropped `verify-rejection` CI job** — PR #1402.
27. **Inkless kafka-exporter sidecar — document in ADR-0015** — PR #1401.
28. **Author ADR-0039 — s3manager (retroactive record)** — PR #1400.
29. **Author ADR-0038 — moto + ACK (S3) + KRO (retroactive record)** — PR
    #1399.
30. **dependency-concentration-sync-check: close the reverse-direction gap**
    — PR #1397.
31. **Add `make dependency-concentration-sync-check`** — PR #1379.
32. **Add `make dependency-exit-runbooks-sync-check`** — PR #1380.
33. **Extend `docs/dependency-exit-runbooks.md` to four single-tool rows** —
    PR #1378.
34. **Close DORA audit Q7's gap — `VaultSealedDegraded` alert rule** — PR
    #1377.

(Numbering above counts sequentially through the write-up; the ROADMAP diff
touches 22 distinct `[x]` items — three items above, #2/#3 and #13/#14/#15,
were fixed together in single multi-item `Edit` calls alongside adjacent
items, so the total edited-block count is 22, matching the "22 items" in
this file's title.)

## Deliberately left alone

Three short blocks matched the scan's length threshold but are legitimate,
non-duplicate annotations, not leftover bugs — left untouched:

- **PSA baseline + NetworkPolicy — `inkless` namespace** — a historical note
  explaining the component was later removed entirely (PR #1424, Aiven
  Inkless retirement); kept per the repo's convention of preserving
  completed-item history even after later removal.
- **GitHub→Forgejo pull-based sync workflow** — a short placeholder-resolved
  note (PR #1347, resolved via GitHub search), not duplicate prose.
- **Lab — Harbor OCI registry dashboard** — the batch-21 stale-PR-link
  bugfix annotation (corrected #318 → #316), a permanent record of that
  correction, not leftover.

## Verification

- `wc -l ROADMAP.md` — 2166 lines (down from 2827 before this batch — 661
  lines removed net, all from deleting genuinely duplicate prose already
  covered by each item's own linked `docs/done/*.md` mirror).
- Every cited PR independently re-verified `merged: true` via direct GitHub
  API calls (`curl` + `$GH_TOKEN`, bypassing an MCP-tool rate-limit hit
  earlier in this cycle) before use, per ADR-0004.
- `make ci` — full local suite green, including `docs-done-pr-link-check`
  and `roadmap-check`.
- This PR is a single-class, all-mechanical, mostly-deletion change
  (699 lines removed / 38 added in the ROADMAP.md diff) — larger than
  WAYS-OF-WORKING.md §3's typical 3-6-item/~400-line batch guideline, but
  scoped to exactly one bug class (leftover prose after an already-applied
  pointer) with zero new prose introduced and zero information lost (every
  deleted paragraph's content already lives in the linked `docs/done/`
  mirror, confirmed by reading each one before editing).

## PR

(placeholder — backfilled after `create_pull_request` returns)
