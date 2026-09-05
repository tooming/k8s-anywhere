# ROADMAP.md legacy `[x]` item trim — batch 12

Continuing the pilot batch, batch 2 through batch 11
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch11.md](2026-09-05-roadmap-legacy-item-trim-batch11.md)).

## What was done

Found and trimmed 6 more large fully-inline `[x]` items (all "no pointer
yet" cases this batch — mostly small currency/pin-hardening bumps), each
re-verified against its real `docs/done/` mirror and a confirmed-
`merged: true` PR before touching the ROADMAP text:

- **Bump Valkey's `redis_exporter` sidecar `v1.88.0-alpine` →
  `v1.89.0-alpine`** →
  [docs/done/2026-08-13-redis-exporter-1-89-0.md](2026-08-13-redis-exporter-1-89-0.md)
  (PR #1178)
- **Pin the TiDB demo's floating `nginx:alpine` tag to
  `nginx:1.31.3-alpine`** →
  [docs/done/2026-08-13-tidb-demo-nginx-explicit-pin.md](2026-08-13-tidb-demo-nginx-explicit-pin.md)
  (PR #1180)
- **Bump Tempo's pinned image `2.10.7` → `2.10.8`** →
  [docs/done/2026-08-13-tempo-2-10-8.md](2026-08-13-tempo-2-10-8.md)
  (PR #1189)
- **Pin `gitlab/docker-compose.yml`'s `gitlab-tls` sidecar to
  `nginx:1.27.5-alpine`** →
  [docs/done/2026-08-13-gitlab-tls-nginx-explicit-pin.md](2026-08-13-gitlab-tls-nginx-explicit-pin.md)
  (PR #1191)
- **Bump `kube-state-metrics` chart `8.0.0` → `8.1.3`** →
  [docs/done/2026-08-05-ksm-chart-8-1-3.md](2026-08-05-ksm-chart-8-1-3.md)
  (PR #1023)
- **Pin Vault's server image tag explicitly** →
  [docs/done/2026-07-24-vault-server-image-tag-pin.md](2026-07-24-vault-server-image-tag-pin.md)
  (PR #699)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all six before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-11, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the established lens to the file's
next tier of largest remaining inline spans.

## Result

`ROADMAP.md`: 5515 → 5215 lines (300 lines saved from 6 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
