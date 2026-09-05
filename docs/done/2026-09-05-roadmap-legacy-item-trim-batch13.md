# ROADMAP.md legacy `[x]` item trim — batch 13

Continuing the pilot batch, batch 2 through batch 12
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch12.md](2026-09-05-roadmap-legacy-item-trim-batch12.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer
yet" cases this batch), each re-verified against its real `docs/done/`
mirror and a confirmed-`merged: true` PR before touching the ROADMAP
text:

- **Bump `grafana` chart `12.10.2` → `12.10.3`** →
  [docs/done/2026-08-05-grafana-chart-12-10-3.md](2026-08-05-grafana-chart-12-10-3.md)
  (PR #991)
- **zz-dns-clusterip-bridge — bring out-of-band CNPs under GitOps** →
  [docs/done/2026-07-02-gitops-clusterip-bridge.md](2026-07-02-gitops-clusterip-bridge.md)
  (PR #324)
- **`tests/frozen-monolith-lib.bats` — direct unit coverage** →
  [docs/done/2026-07-31-auto-frozen-monolith-lib-test-coverage.md](2026-07-31-auto-frozen-monolith-lib-test-coverage.md)
  (PR #954)
- **Bump Pyroscope chart `2.2.0` → `2.2.1` (upstream security release)** →
  [docs/done/2026-08-10-pyroscope-chart-2-2-1.md](2026-08-10-pyroscope-chart-2-2-1.md)
  (PR #1082)
- **Third-party dependency register — `docs/dependency-register.md`** →
  [docs/done/2026-08-04-dependency-register.md](2026-08-04-dependency-register.md)
  (PR #977)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-12, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the established lens to the file's
next tier of largest remaining inline spans.

## Result

`ROADMAP.md`: 5215 → 4986 lines (229 lines saved from 5 items — now
under 5000 lines for the first time since this cleanup started). `make
ci` passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
