# ROADMAP.md legacy `[x]` item trim — batch 18

Continuing the pilot batch, batch 2 through batch 17
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch17.md](2026-09-05-roadmap-legacy-item-trim-batch17.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch — the two largest candidates left over from batch 17's scan,
plus 3 more found this cycle), each re-verified against its real `docs/done/`
mirror and a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump Loki image `grafana/loki:3.7.5` → `3.7.6`** →
  [docs/done/2026-08-06-loki-image-3-7-6.md](2026-08-06-loki-image-3-7-6.md)
  (PR #1042)
- **Bump Envoy Gateway chart `v1.8.2` → `v1.8.3`** →
  [docs/done/2026-07-23-envoy-gateway-chart-1-8-3.md](2026-07-23-envoy-gateway-chart-1-8-3.md)
  (PR #674)
- **Bump Valkey image tag `8.0-alpine` → `8.0.10-alpine`** →
  [docs/done/2026-07-22-valkey-cve-bump-8-0-10.md](2026-07-22-valkey-cve-bump-8-0-10.md)
  (PR #658)
- **Bump Argo Rollouts image tag `v1.9.0` → `v1.9.1`** →
  [docs/done/2026-07-19-argo-rollouts-cve-image-tag.md](2026-07-19-argo-rollouts-cve-image-tag.md)
  (PR #555)
- **KEDA `ScaledObject` demo — scale `rabbitmq-load` on RabbitMQ queue
  depth** →
  [docs/done/2026-07-17-keda-scaledobject-demo.md](2026-07-17-keda-scaledobject-demo.md)
  (PR #459)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-17, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 4203 → 4032 lines (171 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
