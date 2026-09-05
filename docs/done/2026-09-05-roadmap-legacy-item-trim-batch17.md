# ROADMAP.md legacy `[x]` item trim — batch 17

Continuing the pilot batch, batch 2 through batch 16
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
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch16.md](2026-09-05-roadmap-legacy-item-trim-batch16.md)).

## What was done

Found and trimmed 6 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch), each re-verified against its real `docs/done/` mirror and
a confirmed-`merged: true` PR before touching the ROADMAP text:

- **Bump `ack-s3` (AWS Controllers for Kubernetes S3 chart) `1.8.2` →
  `1.9.0`** →
  [docs/done/2026-08-05-ack-s3-chart-1-9-0.md](2026-08-05-ack-s3-chart-1-9-0.md)
  (PR #1009)
- **Bump cert-manager chart `1.21.0` → `1.21.1`** →
  [docs/done/2026-07-31-auto-cert-manager-chart-1-21-1.md](2026-07-31-auto-cert-manager-chart-1-21-1.md)
  (PR #937)
- **Bump Cilium `1.16.6` → `1.17.18`** →
  [docs/done/2026-07-18-cilium-cve-bump.md](2026-07-18-cilium-cve-bump.md)
  (PR #505)
- **Bump Kargo `1.2.3` → `1.6.4`** →
  [docs/done/2026-07-18-kargo-cve-bump-and-fixes.md](2026-07-18-kargo-cve-bump-and-fixes.md)
  (PR #511) — mirror's own title carries extra detail
  ("`(CVE-2026-24748) + three latent config bugs...`") beyond the ROADMAP's
  shorter inline title; confirmed the ROADMAP title is an exact prefix match,
  same convention as prior batches' KEDA/O4 items.
- **Bump Kargo `1.6.4` → `1.10.9`** →
  [docs/done/2026-07-18-kargo-cve-bump-1-10-9.md](2026-07-18-kargo-cve-bump-1-10-9.md)
  (PR #549)
- **Pin Inkless's batch-coordinator `postgres` image explicitly —
  `postgres:17` → `postgres:17.10`** →
  [docs/done/2026-08-05-inkless-postgres-explicit-pin.md](2026-08-05-inkless-postgres-explicit-pin.md)
  (PR #1016)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all six before editing.

Two other large candidates found in this batch's scan (KEDA `ScaledObject`
demo, Argo Rollouts image-tag bump) were deliberately left for a future
batch to keep this one within the usual size.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-16, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16.

## Result

`ROADMAP.md`: 4428 → 4203 lines (225 lines saved from 6 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
