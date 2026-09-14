# Regenerate the on-demand DORA metrics snapshot (`docs/dora-metrics.md`)

Found live 2026-09-14 (STEP 6b PLANNER-fallback filler, ROADMAP rule #9): this
run's STEP 1-3 orient pass found the "Now / next" lane completely empty —
`grep '^- \[ \]' ROADMAP.md` returned zero matches (every backlog item across
every section is `[x]`), `list_pull_requests` (open) returned zero, and
`list_issues` (open) returned zero, so there was nothing to promote and no
issue to groom. Yesterday's run (2026-09-13) already ran three independent
`[Action needed]` fallback-chain cycles that re-verified every pinned
dependency (cert-manager, k3s, the ArgoCD Helm chart, Terraform/Terragrunt),
every GitHub Actions pin, and every doc-drift surface clean — so this cycle
tried a fresh angle instead of repeating that same sweep: the on-demand
generated-report layer, the same class of gap the 2026-09-08
`dora-metrics-refresh-cycle20` item (immediately above this one in
ROADMAP.md's history) already covered once before.

`docs/dora-metrics.md` is a point-in-time snapshot (`make dora-metrics`, RFC
#580, CHARTER Objective O7) — its header explicitly says "Computed
`<timestamp>`", not "live" — and it was still showing its
2026-09-11T00:27:08Z snapshot 3 days and ~20 more first-parent merges later.
Nothing in `make ci` gates its freshness (it's deliberately on-demand, per
the Makefile's own `## ... (RFC #580, on-demand only)` comment, same as
`scripts/ondemand-budget-check.sh`'s sibling tools) — so this is a currency
gap only a sweep like this one surfaces, not a drift-detector miss. Live
upstream currency was also independently re-checked this cycle (cert-manager
`v1.21.2`, k3s `v1.36.4+k3s1` with `v1.37.0` still at `-rc5`, the ArgoCD Helm
chart `10.9.0`/`v3.5.2`, Terraform `v1.16.2`) — all four confirmed still
current, so no upgrade PR was due; this item is the one real, verifiable
piece of drift this cycle's checks turned up.

## What was done

Ran `make dora-metrics` (`scripts/dora-metrics.sh`) to regenerate
`docs/dora-metrics.md` against the repo's current history (the script
detected and correctly deepened this session's shallow clone before
measuring, per its own shallow-clone-correction logic):

- Computed timestamp: `2026-09-11T00:27:08Z` → `2026-09-14T06:39:04Z`.
- Deployment frequency: `97.67/week (1256 in 90d)` → `99.22/week (1276 in
  90d)` — the higher count is genuinely earned: 20 more first-parent commits
  landed on `main` in the 3 days since the prior snapshot.
- Change failure rate: `9.6% (120/1256)` → `9.4% (120/1276)` — the failure
  count itself didn't change; the rate moved because the denominator grew.
- Lead time / time to restore service: both remain "insufficient data (gh
  CLI or jq not available)" — unchanged, since this environment has neither
  `gh` nor the GitHub PR API available to compute them; still correctly
  honest per ADR-0004 rather than estimated.

Confirmed no other doc hardcodes the stale numbers this replaced (`grep -rn`
across `docs/*.md`, `README.md`, `CHARTER.md` for the old values returned
nothing) — same result as the 2026-09-08 refresh: `docs/dora-audit-readiness.md`
and `docs/dora-resilience-mapping.md` both reference the metrics file by
link/row-name rather than quoting a specific number, so no follow-up edit was
needed there.

## Validation

`make ci` — full local run (bats + kustomize + terraform + drift checks).
`scripts/dora-metrics.sh` itself is idempotent and side-effect-free beyond
rewriting `docs/dora-metrics.md` from live `git log` data (no live-cluster or
`gh`/network dependency exercised in this environment beyond what was already
unavailable before this change).

## PR

(auto/dora-metrics-refresh-20260914) — autonomous scheduled executor run,
STEP 6b PLANNER-fallback filler after confirming the backlog was genuinely
empty and yesterday's three `[Action needed]` cycles had already swept every
other currency angle clean.
