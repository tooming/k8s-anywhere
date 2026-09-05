# ROADMAP.md legacy `[x]` item trim — batch 9

Continuing the pilot batch, batch 2 through batch 8
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items, again using both
established lenses, each re-verified against its real `docs/done/` mirror
and a confirmed-`merged: true` PR before touching the ROADMAP text:

- **GitOps-track the `harbor.127.0.0.1.nip.io`-class in-cluster DNS
  rewrite found live in PR #1323** →
  [docs/done/2026-08-25-coredns-nip-io-gitops-tracking.md](2026-08-25-coredns-nip-io-gitops-tracking.md)
  (PR #1326) — already had the pointer, ~55 lines of duplicated prose
  still below it.
- **Fix two Grafana Unified Alerting rules that can never fire
  (threshold-vs-stateSet-metric bug)** →
  [docs/done/2026-08-13-alerting-threshold-bool-fix.md](2026-08-13-alerting-threshold-bool-fix.md)
  (PR #1187) — no pointer yet; ~68 lines of full spec.
- **Bump Grafana image tag `13.0.3` → `13.0.5` (security fix) + correct
  ADR-0006's stale Tempo pin citation** →
  [docs/done/2026-08-06-grafana-image-13-0-5.md](2026-08-06-grafana-image-13-0-5.md)
  (PR #1044) — no pointer yet; ~64 lines of full spec.
- **Bump Vault's pinned image `hashicorp/vault:2.0.3` → `2.0.4` (server +
  unsealer)** →
  [docs/done/2026-08-05-vault-image-2-0-4.md](2026-08-05-vault-image-2-0-4.md)
  (PR #1011) — no pointer yet; ~67 lines of full spec.
- **Incident classification (severity) scheme + incident log** →
  [docs/done/2026-08-04-incident-severity-scheme-log.md](2026-08-04-incident-severity-scheme-log.md)
  (PR #973) — no pointer yet; ~68 lines of full spec.

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-8, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the same two lenses to the file's next
tier of largest remaining inline spans.

## Result

`ROADMAP.md`: 6390 → 6071 lines (319 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1419
