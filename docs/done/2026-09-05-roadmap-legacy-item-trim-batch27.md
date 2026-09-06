# ROADMAP.md legacy `[x]` item trim — batch 27

Continuing the pilot batch, batch 2 through batch 26
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch26.md](2026-09-05-roadmap-legacy-item-trim-batch26.md)).

## What was done

Found and trimmed 6 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump RabbitMQ `3.13` → `4.3.x`** →
  [docs/done/2026-07-18-rabbitmq-bump-4x.md](2026-07-18-rabbitmq-bump-4x.md)
  (PR #525)
- **`docs/00-architecture.md` — current-state rewrite** →
  [docs/done/2026-06-25-auto-architecture-doc-rewrite.md](2026-06-25-auto-architecture-doc-rewrite.md)
  (PR #273)
- **O5 dashboard-coverage bats — always-on service apps** →
  [docs/done/2026-07-04-auto-o5-dashboard-coverage-bats.md](2026-07-04-auto-o5-dashboard-coverage-bats.md)
  (PR #328 — found via `search_pull_requests` on the branch name)
- **NetworkPolicy bats fan-out — Tier-1 wave overlays** →
  [docs/done/2026-07-04-networkpolicy-tier1-bats.md](2026-07-04-networkpolicy-tier1-bats.md)
  (PR #329)
- **Lab — TiDB on-demand Alloy scrape + dashboard** →
  [docs/done/2026-07-05-auto-tidb-dashboard.md](2026-07-05-auto-tidb-dashboard.md)
  (PR #332)
- **O2 measurement — per-scope NP bats for 3 late-addition namespaces** →
  [docs/done/2026-07-06-auto-networkpolicy-tier1-bats-wave2.md](2026-07-06-auto-networkpolicy-tier1-bats-wave2.md)
  (PR #336 — found via `search_pull_requests` on the branch name)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all six before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-26, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 3208 → 3044 lines (164 lines saved from 6 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1440
