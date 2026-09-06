# ROADMAP.md legacy `[x]` item trim — batch 28

Continuing the pilot batch, batch 2 through batch 27
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch22.md](2026-09-05-roadmap-legacy-item-trim-batch22.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch23.md](2026-09-05-roadmap-legacy-item-trim-batch23.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch24.md](2026-09-05-roadmap-legacy-item-trim-batch24.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch25.md](2026-09-05-roadmap-legacy-item-trim-batch25.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch26.md](2026-09-05-roadmap-legacy-item-trim-batch26.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch27.md](2026-09-05-roadmap-legacy-item-trim-batch27.md)).

## What was done

Found and trimmed 4 more items this batch, each re-verified against its real
`docs/done/` mirror and a confirmed-`merged: true` PR before touching the
ROADMAP text:

- **Harbor day-0 credential seam — admin + CI registry secrets** →
  [docs/done/2026-07-08-harbor-bootstrap-credentials.md](2026-07-08-harbor-bootstrap-credentials.md)
  (PR #347)
- **Hook-scripts negative-path coverage —
  `argocd-crd-ssa-sync-hook.sh` + `helm-chart-pin-sync-hook.sh`** →
  [docs/done/2026-07-16-hook-scripts-negative-path-coverage.md](2026-07-16-hook-scripts-negative-path-coverage.md)
  (PR #432)
- **Longhorn currency re-check — `v1.12.1` now stable, kept at `1.11.3`** —
  **a partial-trim cleanup, not a fresh find**: this item already carried a
  "full verification writeup" pointer to
  [docs/done/2026-09-03-longhorn-currency-recheck-kept.md](2026-09-03-longhorn-currency-recheck-kept.md)
  (PR #1398), but ~20 lines of the original verbose prose remained
  duplicated directly below the pointer instead of being removed — a gap
  the batch-16-onward `awk` scan (which excludes any block already
  containing the phrase) doesn't catch, since it only checks for presence
  of the phrase, not that the block is *only* the pointer. Removed the
  redundant trailing prose, keeping just the pointer + branch/PR citation.
- **ADR-0006 — remove stale "Follow-up: wire both bootstraps into
  `make up`/DR" note** →
  [docs/done/2026-07-18-adr-0006-stale-followup-note.md](2026-07-18-adr-0006-stale-followup-note.md)
  (PR #551)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all four before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-27, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment. PR
#1441 (`upgrade/kro-0.9.3-to-0.9.4`) appeared this cycle from a concurrent
executor session running the UPGRADE-DRAFTER fallback role — a distinct
session ID from this one, freshly opened, not stranded — left untouched per
STEP 1b; its own session owns it. JANITOR continues the established
legacy-item-trim cleanup, this batch also catching a partially-completed
prior trim (see above) via a broader content-grep sweep.

## Result

`ROADMAP.md`: 3044 → 2964 lines (80 lines saved from 4 items/cleanups).
`make ci` passes green (lint, README/lab-UI/roadmap drift checks, ADR
chart/image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed in
this remote clusterless session, so those steps no-op locally as usual — the
real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1442
