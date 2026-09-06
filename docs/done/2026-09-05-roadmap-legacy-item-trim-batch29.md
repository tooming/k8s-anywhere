# ROADMAP.md legacy `[x]` item trim — batch 29

JANITOR-fallback cleanup (STEP 6b), continuing the chain of prior batches:
[batch 15](2026-09-05-roadmap-legacy-item-trim-batch15.md),
[batch 16](2026-09-05-roadmap-legacy-item-trim-batch16.md),
[batch 17](2026-09-05-roadmap-legacy-item-trim-batch17.md),
[batch 18](2026-09-05-roadmap-legacy-item-trim-batch18.md),
[batch 19](2026-09-05-roadmap-legacy-item-trim-batch19.md),
[batch 20](2026-09-05-roadmap-legacy-item-trim-batch20.md),
[batch 21](2026-09-05-roadmap-legacy-item-trim-batch21.md),
[batch 22](2026-09-05-roadmap-legacy-item-trim-batch22.md),
[batch 23](2026-09-05-roadmap-legacy-item-trim-batch23.md),
[batch 24](2026-09-05-roadmap-legacy-item-trim-batch24.md),
[batch 25](2026-09-05-roadmap-legacy-item-trim-batch25.md),
[batch 26](2026-09-05-roadmap-legacy-item-trim-batch26.md),
[batch 27](2026-09-05-roadmap-legacy-item-trim-batch27.md),
[batch 28](2026-09-05-roadmap-legacy-item-trim-batch28.md).

## Why in scope

Re-walked the STEP 6b fallback chain fresh this cycle: issues #633 (Argo
Rollouts canary + Kargo promotion end-to-end confirmation) and #1229 (KUBECONFIG
Forgejo Actions secret) both remain open/unconfirmed, so the "Now / next"
ROADMAP lane is still fully gated. No open PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER work was found. Sibling sessions' PRs observed this
cycle and left untouched per STEP 1b: #1424 (human `tooming`, Inkless removal),
#1434 (live-cluster session, Harbor jobservice GODEBUG fix), #1441 (a different
executor session, KRO 0.9.3→0.9.4 upgrade-drafter). JANITOR falls through to
the established ROADMAP.md legacy-item-trim cleanup.

## Items trimmed this batch

Each item's full verbose inline text was replaced with a pointer to its
existing `docs/done/*.md` record, after independently re-verifying the cited
PR's `merged: true` state via the GitHub API (ADR-0004 — never trust a prior
claim blindly):

- **Lab — KSM cluster health dashboard** — mirror:
  [docs/done/auto-ksm-cluster-health-dashboard.md](auto-ksm-cluster-health-dashboard.md)
  — PR #242 (verified `merged: true`).
- **Lab — Node Exporter vitals dashboard** — mirror:
  [docs/done/2026-06-21-node-exporter-vitals-dashboard.md](2026-06-21-node-exporter-vitals-dashboard.md)
  — PR #245 (verified `merged: true`).
- **ADR-0017 restricted-profile Kargo row** — mirror already cited PR #291
  (verified `merged: true`).
- **O2 NP per-scope coverage loop bats** — mirror:
  [docs/done/2026-07-07-o2-np-coverage-loop.md](2026-07-07-o2-np-coverage-loop.md)
  — PR #343 (verified `merged: true`).
- **NetworkPolicy overlay — `capstone-pipeline` namespace** — mirror:
  [docs/done/2026-07-11-auto-capstone-pipeline-networkpolicy.md](2026-07-11-auto-capstone-pipeline-networkpolicy.md)
  — PR #363 (verified `merged: true`). This item's prior "blocked on PR #354"
  gating note is now moot (#354 merged long ago) and was removed along with
  the rest of the inline prose.

## Verification

- `wc -l ROADMAP.md` — 2873 lines (down from 2877 before this batch's net
  edits; the five inline blocks removed were replaced by four-line pointers).
- `make ci` — full local suite green, including
  `docs-done-pr-link-check.sh` (every `docs/done/*.md` file has a real PR
  link, no unresolved placeholder) and `roadmap-check`.

## PR

(placeholder — backfilled after `create_pull_request` returns)
