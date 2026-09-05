# ROADMAP.md legacy `[x]` item trim — batch 8

Continuing the pilot batch, batch 2 through batch 7
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items with a real,
verified `docs/done/` mirror and a confirmed-`merged: true` PR, using
both established lenses (no pointer yet, and a pointer already present
alongside leftover duplicated prose):

- **k3d containerd registry mirror — resolve `harbor.127.0.0.1.nip.io`
  in-cluster** →
  [docs/done/2026-08-07-k3d-registry-mirror-harbor.md](2026-08-07-k3d-registry-mirror-harbor.md)
  (PR #1080) — no pointer yet; ~84 lines of full spec.
- **Bump Terraform-bootstrapped `argo-cd` chart `10.2.2` → `10.2.3`** →
  [docs/done/2026-08-05-argocd-chart-10-2-3.md](2026-08-05-argocd-chart-10-2-3.md)
  (PR #993) — no pointer yet; ~83 lines of full spec. (Two sibling
  `argo-cd` chart-bump items — `10.2.3`→`10.3.0` and `10.3.2`→`10.3.3` —
  were left untouched this batch; each needs its own separate mirror
  lookup and wasn't yet verified.)
- **Close DORA audit Q15's named gap — `make dependency-maintenance-check`**
  → [docs/done/2026-09-02-dependency-maintenance-check.md](2026-09-02-dependency-maintenance-check.md)
  (PR #1375) — already had the pointer, ~77 lines of duplicated prose
  still below it.
- **Vault internal telemetry — `sys/metrics` scrape + dashboard depth** →
  [docs/done/2026-08-11-vault-telemetry-scrape.md](2026-08-11-vault-telemetry-scrape.md)
  (PR #1127) — no pointer yet; ~71 lines of full spec.
- **Loki / Tempo / Pyroscope operational-health dashboards — O5 gap** →
  [docs/done/2026-08-11-lgtmp-health-dashboards.md](2026-08-11-lgtmp-health-dashboards.md)
  (PR #1131) — no pointer yet; ~75 lines of full spec.

Every PR link was verified directly via the GitHub API (`merged: true`)
before being written, and each mirror file's content was read and
confirmed to already carry the same detail as the trimmed ROADMAP text
(ADR-0004 — no information discarded, only de-duplicated).

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batch 7, re-confirmed fresh this cycle: the
three "Now / next" items remain gated (issues #633/#1229, no new
confirmation); PLANNER/ARCHITECT still have nothing (zero ungroomed
intake, zero un-RFC'd 🟡 items, zero `docs/roadmap/incoming/` files);
`make ci` shows zero drift; TRIAGER's 3 open issues are all already fully
labeled. JANITOR continues the same established legacy-item-trim
cleanup — this batch simply applied the same two lenses more widely
across the file's largest remaining inline spans (found via a line-count
scan of every `- [x]` item's body).

## Result

`ROADMAP.md`: 6759 → 6390 lines (369 lines saved from 5 items — the
largest single-batch saving yet, several items having no pointer at all).
`make ci` passes green (lint, README/lab-UI/roadmap drift checks, ADR
chart/image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
