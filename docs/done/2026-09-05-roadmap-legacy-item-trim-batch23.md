# ROADMAP.md legacy `[x]` item trim — batch 23

Continuing the pilot batch, batch 2 through batch 22
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch9.md](2026-09-05-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch10.md](2026-09-05-roadmap-legacy-item-trim-batch10.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch11.md](2026-09-05-roadmap-legacy-item-trim-batch11.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch12.md](2026-09-05-roadmap-legacy-item-trim-batch12.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch13.md](2026-09-05-roadmap-legacy-item-trim-batch13.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch14.md](2026-09-05-roadmap-legacy-item-trim-batch14.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch15.md](2026-09-05-roadmap-legacy-item-trim-batch15.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch16.md](2026-09-05-roadmap-legacy-item-trim-batch16.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch17.md](2026-09-05-roadmap-legacy-item-trim-batch17.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch18.md](2026-09-05-roadmap-legacy-item-trim-batch18.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch19.md](2026-09-05-roadmap-legacy-item-trim-batch19.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch20.md](2026-09-05-roadmap-legacy-item-trim-batch20.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch21.md](2026-09-05-roadmap-legacy-item-trim-batch21.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch22.md](2026-09-05-roadmap-legacy-item-trim-batch22.md)).

## What was done

Found and trimmed 3 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **External Secrets dashboard + Alloy scrape** →
  [docs/done/2026-06-19-external-secrets-dashboard.md](2026-06-19-external-secrets-dashboard.md)
  (PR #234 — found via `search_pull_requests` on the branch name, since the
  mirror file carried no PR reference at all)
- **Bump Longhorn `1.7.3` → `1.11.x`** →
  [docs/done/2026-07-18-longhorn-bump-1-11.md](2026-07-18-longhorn-bump-1-11.md)
  (PR #531)
- **PSA baseline + NetworkPolicy — `inkless` namespace** →
  [docs/done/2026-06-23-pss-np-inkless.md](2026-06-23-pss-np-inkless.md)
  (PR #260) — Inkless itself was later removed entirely (PR #1424); the
  trimmed ROADMAP text now explicitly notes this is historical record of
  completed work, not live state, per this repo's standing convention of
  never rewriting completed-item history after later removal.

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all three before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-22, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment yet. One
new PR (#1434, `fix(harbor): add missing GODEBUG=asyncpreemptoff=1 to
jobservice`) appeared this cycle from a live-cluster/interactive session
actively working issue #633 on a real cluster — not stranded, not part of
this executor's own lineage, left untouched per STEP 1b; its own author's
session owns it. JANITOR continues the established legacy-item-trim cleanup
using the same targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 3549 → 3475 lines (74 lines saved from 3 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
