# ROADMAP.md legacy `[x]` item trim — batch 25

Continuing the pilot batch, batch 2 through batch 24
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch24.md](2026-09-05-roadmap-legacy-item-trim-batch24.md)).

## What was done

Found and trimmed 3 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Governance LimitRange fan-out — `cert-manager` + `keda`** →
  [docs/done/2026-07-16-governance-cert-manager-keda.md](2026-07-16-governance-cert-manager-keda.md)
  (PR #451)
- **Argo Rollouts dashboard + Alloy scrape job** →
  [docs/done/2026-06-15-argo-rollouts-dashboard.md](2026-06-15-argo-rollouts-dashboard.md)
  (PR #211 — found via `search_pull_requests` on the branch name, since the
  mirror file carried no PR reference at all)
- **PSS `privileged` labels + NetworkPolicy — `istio-system`** →
  [docs/done/2026-06-27-pss-np-istio-system.md](2026-06-27-pss-np-istio-system.md)
  (PR #285 — same, found via branch-name search)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all three before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-24, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment yet. PR
#1434 (a live-cluster session's Harbor fix) remains open, rebased onto the
latest main by its own author's session — still not part of this executor's
lineage, left untouched. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 3384 → 3318 lines (66 lines saved from 3 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
