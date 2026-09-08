# Regenerate the on-demand DORA metrics snapshot (`docs/dora-metrics.md`)

Found live 2026-09-08 (cycle 20 of this autonomous run — a fresh lens: the
on-demand generated-report layer, not application/infra/CI currency, all
already swept clean in cycles 17-19). `docs/dora-metrics.md` is a
point-in-time snapshot (`make dora-metrics`, RFC #580, CHARTER Objective
O7) — its header explicitly says "Computed `<timestamp>`", not "live" —
and it was still showing its 2026-09-03T01:55:53Z snapshot after 5 more
days and ~20 more merged PRs from this run alone (#1513–#1532). Nothing in
`make ci` gates its freshness (it's deliberately on-demand, per the
Makefile's own `## ... (RFC #580, on-demand only)` comment, same as
`scripts/ondemand-budget-check.sh`'s sibling tools) — so this is a
currency gap only a sweep like this one surfaces, not a drift-detector
miss.

## What was done

Ran `make dora-metrics` (`scripts/dora-metrics.sh`) to regenerate
`docs/dora-metrics.md` against the repo's current history:

- Computed timestamp: `2026-09-03T01:55:53Z` → `2026-09-08T03:47:42Z`.
- Deployment frequency: `90.59/week (1165 in 90d)` → `98.99/week (1273 in
  90d)` — the higher rate is genuinely earned: this run alone landed ~20
  first-parent commits onto `main` since the prior snapshot.
- Change failure rate: `8.9% (104/1165)` → `9.6% (122/1273)`.
- Lead time / time to restore service: both remain "insufficient data (gh
  CLI or jq not available)" — unchanged, since this environment has
  neither `gh` nor the GitHub PR API available to compute them; still
  correctly honest per ADR-0004 rather than estimated.

Confirmed no other doc hardcodes the stale numbers this replaced
(`grep -rn` across `docs/*.md`, `README.md`, `CHARTER.md` for the old
values returned nothing) — `docs/dora-audit-readiness.md` and
`docs/dora-resilience-mapping.md` both already reference the metrics file
by link/row-name rather than quoting a specific number, so no follow-up
edit was needed there.

## Validation

`make ci` — full local run (bats + kustomize + terraform + drift checks).
`scripts/dora-metrics.sh` itself is idempotent and side-effect-free beyond
rewriting `docs/dora-metrics.md` from live `git log` data (no live-cluster
or `gh`/network dependency exercised in this environment beyond what was
already unavailable before this change).

## PR

[#1533](https://github.com/tooming/k8s-anywhere/pull/1533) (autonomous
scheduled executor run, cycle 20 — a fresh lens on the on-demand
generated-report layer, after cycles 17-19 already swept application,
infra/CI, and CI-workflow-configuration currency clean).
