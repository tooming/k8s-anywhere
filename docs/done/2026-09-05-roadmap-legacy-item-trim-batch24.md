# ROADMAP.md legacy `[x]` item trim — batch 24

Continuing the pilot batch, batch 2 through batch 23
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch23.md](2026-09-05-roadmap-legacy-item-trim-batch23.md)).

## What was done

Found and trimmed 4 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump KRO chart `0.4.1` → `0.9.x` — verify CRD/instance-scope
  compatibility first** →
  [docs/done/2026-07-18-kro-bump-0-9.md](2026-07-18-kro-bump-0-9.md)
  (PR #537)
- **Name O3's RPO target explicitly in CHARTER.md** →
  [docs/done/2026-08-07-charter-o3-rpo-target.md](2026-08-07-charter-o3-rpo-target.md)
  (PR #1060)
- **Harbor governance LimitRange** →
  [docs/done/2026-07-03-auto-harbor-governance-limitrange.md](2026-07-03-auto-harbor-governance-limitrange.md)
  (PR #327)
- **Velero chart major bump `8.7.2` → `12.1.0`** →
  [docs/done/2026-07-20-velero-chart-bump-12-1-0.md](2026-07-20-velero-chart-bump-12-1-0.md)
  (PR #620)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all four before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-23, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment yet.
PR #1434 (a live-cluster session's Harbor fix, referencing #633) remains open
and unmerged, still not part of this executor's lineage — left untouched.
JANITOR continues the established legacy-item-trim cleanup using the same
targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 3475 → 3384 lines (91 lines saved from 4 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
