# ROADMAP.md legacy `[x]` item trim — batch 11

Continuing the pilot batch, batch 2 through batch 10
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch9.md](2026-09-05-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch10.md](2026-09-05-roadmap-legacy-item-trim-batch10.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer
yet" cases this batch), each re-verified against its real `docs/done/`
mirror and a confirmed-`merged: true` PR before touching the ROADMAP
text:

- **Bump Terraform-bootstrapped `argo-cd` chart `10.2.3` → `10.3.0`** →
  [docs/done/2026-08-07-argocd-chart-10-3-0.md](2026-08-07-argocd-chart-10-3-0.md)
  (PR #1056)
- **Replace the dead "idle issue" fallback across every routine prompt
  with a `[Action needed]` PR** →
  [docs/done/2026-07-19-action-needed-pr-fallback.md](2026-07-19-action-needed-pr-fallback.md)
  (PR #578) — its "PR 2 of 2" sibling item directly below it (remaining
  five routine prompts) was deliberately left untouched this batch, not
  yet re-verified.
- **Chaos / fault-injection drill — `make dr-chaos`** →
  [docs/done/2026-08-04-dr-chaos-fault-injection.md](2026-08-04-dr-chaos-fault-injection.md)
  (PR #975)
- **DR/capstone-demo results-history log — track pass/fail + elapsed
  time per run over time** →
  [docs/done/2026-08-11-dr-results-log.md](2026-08-11-dr-results-log.md)
  (PR #1125)
- **Stateless-surface criticality tiering — closes DORA audit Q2's named
  gap** →
  [docs/done/2026-08-12-stateless-criticality-tiers.md](2026-08-12-stateless-criticality-tiers.md)
  (PR #1133)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before
editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-10, re-confirmed fresh this cycle:
the three "Now / next" items remain gated; PLANNER/ARCHITECT still have
nothing; `make ci` shows zero drift; TRIAGER's 3 open issues are all
already fully labeled. JANITOR continues the same established
legacy-item-trim cleanup, applying the established lens to the file's
next tier of largest remaining inline spans.

## Result

`ROADMAP.md`: 5782 → 5515 lines (267 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/
image-pin sync, dependency-register sync, every `docs/done/` file's
PR-link check all clean; `bats`/`kustomize`/`terraform` aren't installed
in this remote clusterless session, so those steps no-op locally as usual
— the real backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1421
