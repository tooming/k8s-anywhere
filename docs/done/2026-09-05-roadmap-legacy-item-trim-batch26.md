# ROADMAP.md legacy `[x]` item trim — batch 26

Continuing the pilot batch, batch 2 through batch 25
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch25.md](2026-09-05-roadmap-legacy-item-trim-batch25.md)).

## What was done

Found and trimmed 4 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Lab — Grafana Alloy self-monitoring dashboard + self-scrape** →
  [docs/done/2026-06-20-auto-alloy-self-monitoring.md](2026-06-20-auto-alloy-self-monitoring.md)
  (PR #241 — found via `search_pull_requests` on the branch name, since the
  mirror file carried no PR reference at all)
- **Lab — `demo` + `data-demo` dashboards (O5 completion)** →
  [docs/done/2026-06-24-demo-data-demo-dashboards.md](2026-06-24-demo-data-demo-dashboards.md)
  (PR #264)
- **O2 measurement — per-scope PSS bats for 5 Tier-1 wave namespaces** →
  [docs/done/2026-07-06-auto-securitycontext-tier1-bats.md](2026-07-06-auto-securitycontext-tier1-bats.md)
  (PR #335)
- **Cilium agent Prometheus metrics + O5 CNI dashboard** →
  [docs/done/2026-07-12-auto-cilium-agent-metrics.md](2026-07-12-auto-cilium-agent-metrics.md)
  (PR #367)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all four before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-25, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment yet. PR
#1434 (a live-cluster session's Harbor fix) merged separately during this
cycle, cleanly fast-forwarding onto main — unrelated to this executor's
lineage, no action taken on it. JANITOR continues the established
legacy-item-trim cleanup using the same targeted `awk` scan introduced in
batch 16.

## Result

`ROADMAP.md`: 3318 → 3208 lines (110 lines saved from 4 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
