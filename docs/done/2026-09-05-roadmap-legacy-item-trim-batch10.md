# ROADMAP.md legacy `[x]` item trim — batch 10

Continuing the pilot batch, batch 2 through batch 9
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch9.md](2026-09-05-roadmap-legacy-item-trim-batch9.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer
yet" cases this batch), each re-verified against its real `docs/done/`
mirror and a confirmed-`merged: true` PR before touching the ROADMAP
text:

- **Bump Terraform-bootstrapped `argo-cd` chart `10.3.2` → `10.3.3`
  (appVersion `v3.5.0` → `v3.5.1`)** →
  [docs/done/2026-08-13-argocd-chart-10-3-3.md](2026-08-13-argocd-chart-10-3-3.md)
  (PR #1182)
- **Vault pod-readiness alert rule — extend Grafana Unified Alerting
  (RFC #1084)** →
  [docs/done/2026-08-11-vault-pod-readiness-alert.md](2026-08-11-vault-pod-readiness-alert.md)
  (PR #1119)
- **Bump Trivy Operator chart `0.34.0` → `0.35.0`** →
  [docs/done/2026-08-07-trivy-operator-chart-0-35-0.md](2026-08-07-trivy-operator-chart-0-35-0.md)
  (PR #1057)
- **Bump Harbor chart `1.19.1` → `1.19.2`** →
  [docs/done/2026-08-03-harbor-chart-1-19-2.md](2026-08-03-harbor-chart-1-19-2.md)
  (PR #963)
- **Bump External Secrets Operator chart `2.8.0` → `2.9.0` (real CVE
  fixes)** →
  [docs/done/2026-08-10-external-secrets-chart-2-9-0.md](2026-08-10-external-secrets-chart-2-9-0.md)
  (PR #1081)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-9, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the established lens to the file's
next tier of largest remaining inline spans (mostly currency/CVE bump
items whose full diligence write-ups were never given a short pointer).

## Result

`ROADMAP.md`: 6071 → 5782 lines (289 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1420
