# ROADMAP.md legacy `[x]` item trim — batch 14

Continuing the pilot batch, batch 2 through batch 13
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch13.md](2026-09-05-roadmap-legacy-item-trim-batch13.md)).

## What was done

Found and trimmed 4 more large fully-inline `[x]` items (all "no pointer
yet" cases this batch), each re-verified against its real `docs/done/`
mirror and a confirmed-`merged: true` PR before touching the ROADMAP
text:

- **Lab — Istio ambient mesh (`istio-system`) observability wiring: Alloy
  scrape + Grafana dashboard** →
  [docs/done/2026-07-28-istio-observability-dashboard.md](2026-07-28-istio-observability-dashboard.md)
  (PR #824)
- **`scripts/dora-metrics.sh` + `make dora-metrics` — DORA metrics from
  git/CI history** →
  [docs/done/2026-07-19-dora-metrics.md](2026-07-19-dora-metrics.md)
  (PR #584)
- **Grafana Unified Alerting — four rules for known failure conditions**
  →
  [docs/done/2026-08-10-grafana-alerting-rules.md](2026-08-10-grafana-alerting-rules.md)
  (PR #1087)
- **PSA `restricted` labels — `capstone-pipeline` namespace** →
  [docs/done/2026-07-09-auto-capstone-pipeline-psa.md](2026-07-09-auto-capstone-pipeline-psa.md)
  (PR #354)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all four before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-13, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the established lens to the file's
next tier of largest remaining inline spans. This batch was smaller (4
items instead of 5) since the lens is thinning as the file shrinks.

## Result

`ROADMAP.md`: 4986 → 4834 lines (152 lines saved from 4 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1425
