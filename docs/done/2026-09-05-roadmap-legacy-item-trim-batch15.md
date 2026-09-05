# ROADMAP.md legacy `[x]` item trim — batch 15

Continuing the pilot batch, batch 2 through batch 14
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch14.md](2026-09-05-roadmap-legacy-item-trim-batch14.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and a
confirmed-`merged: true` PR before touching the ROADMAP text:

- **`docs/dora-resilience-mapping.md` — DORA (EU regulation) pillar mapping,
  explicitly not a compliance claim** →
  [docs/done/2026-07-19-dora-resilience-mapping.md](2026-07-19-dora-resilience-mapping.md)
  (PR #589)
- **Bump Grafana image tag `13.0.1` → `13.0.3`** →
  [docs/done/2026-07-19-grafana-cve-bump-13-0-3.md](2026-07-19-grafana-cve-bump-13-0-3.md)
  (PR #566)
- **Pin k3s to an explicit version on every backend** →
  [docs/done/2026-07-19-k3s-version-pin.md](2026-07-19-k3s-version-pin.md)
  (PR #561)
- **KEDA event-driven autoscaling engine** →
  [docs/done/2026-07-16-keda-engine.md](2026-07-16-keda-engine.md)
  (PR #444)
- **O4 CI gate — `verify-image-rejection` job** →
  [docs/done/2026-08-18-o4-ci-rejection-gate.md](2026-08-18-o4-ci-rejection-gate.md)
  (PR #1224)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-14, re-confirmed fresh this cycle: the
three "Now / next" items remain gated; PLANNER/ARCHITECT still have nothing;
`make ci` shows zero drift; TRIAGER's 3 open issues are all already fully
labeled. Also checked in this cycle: an unrelated PR #1424
(`chore/remove-inkless`) appeared from another, actively-owned session
(opened by the repo's actual user 12 minutes before this cycle started) — not
stranded, not part of this executor lineage, left untouched. JANITOR
continues the same established legacy-item-trim cleanup, applying the
established lens to the file's next tier of largest remaining inline spans.

## Result

`ROADMAP.md`: 4834 → 4625 lines (209 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1426
