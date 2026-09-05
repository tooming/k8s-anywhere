# ROADMAP.md legacy `[x]` item trim — batch 16

Continuing the pilot batch, batch 2 through batch 15
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch15.md](2026-09-05-roadmap-legacy-item-trim-batch15.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and a
confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump `kiali-server` chart `2.29.0` → `2.30.0`** →
  [docs/done/2026-08-04-kiali-chart-2-30-0.md](2026-08-04-kiali-chart-2-30-0.md)
  (PR #970)
- **Bump k3s pin `v1.36.2+k3s1` → `v1.36.3+k3s1` on both backends** →
  [docs/done/2026-08-05-k3s-1-36-3.md](2026-08-05-k3s-1-36-3.md)
  (PR #998)
- **Bump Loki image `grafana/loki:3.7.4` → `3.7.5`** →
  [docs/done/2026-08-06-loki-image-3-7-5.md](2026-08-06-loki-image-3-7-5.md)
  (PR #1033)
- **Harbor on-demand Application + namespace + Envoy route** →
  [docs/done/2026-06-30-harbor-application.md](2026-06-30-harbor-application.md)
  (PR #306)
- **Fix stale `(follow-up item)` markers in ADR-0028/ADR-0029 + widen
  `scripts/adr-followup-check.sh` to catch the parenthetical form** →
  [docs/done/2026-07-19-adr-followup-parenthetical-form.md](2026-07-19-adr-followup-parenthetical-form.md)
  (PR #601)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-15, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment since
last checked (`updated_at` unchanged); both are still standing, fully
labeled, and the only 2 open issues in the repo, so TRIAGER has nothing.
PLANNER/ARCHITECT still have nothing (no open PRs besides this lineage after
PR #1424 merged; no un-RFC'd 🟡 items found). JANITOR continues the
established legacy-item-trim cleanup — this time located candidates with a
targeted `awk` scan for the largest still-inline `[x]` blocks lacking the
"full verification writeup" pointer pattern, rather than only the
previously-used size-ranked grep.

## Result

`ROADMAP.md`: 4625 → 4428 lines (197 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync — including the `37`-row scope-note arithmetic
already reflecting the separately-merged Inkless removal (PR #1424) — every
`docs/done/` file's PR-link check all clean; `bats`/`kustomize`/`terraform`
aren't installed in this remote clusterless session, so those steps no-op
locally as usual — the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1427
