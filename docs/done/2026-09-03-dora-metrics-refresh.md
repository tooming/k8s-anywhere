# Refresh `docs/dora-metrics.md` (stale since 2026-07-30)

`docs/dora-metrics.md` (CHARTER Objective O7) was last computed 2026-07-30 —
over a month stale, and this run alone landed 8 merged PRs, meaningfully
changing the trailing-90-day window's real numbers. Re-ran `make dora-metrics`
(`scripts/dora-metrics.sh`) to regenerate it from real `git log` history.

Verified directly (not assumed, ADR-0004): confirmed this session's clone is not
shallow (`git rev-parse --is-shallow-repository` → `false`, 1455 commits present)
before trusting the output — the script's own header comment documents a real
prior bug where a shallow clone silently produced a badly undercounted number with
no warning (2026-07-21 finding); a shallow clone here would render "insufficient
data" instead per the script's own shallow-clone guard, so a real number coming
back is itself evidence the guard passed.

## What changed

`docs/dora-metrics.md`:
- Deployment frequency: `65.16 deployments/week (838 in 90d window)` → `90.59
  deployments/week (1165 in 90d window)`.
- Change failure rate: `6.8% (57/838 deployments)` → `8.9% (104/1165
  deployments)`.
- Lead time for changes / time to restore service: unchanged, still
  "insufficient data (gh CLI or jq not available)" — this remote clusterless
  session doesn't have the `gh` CLI installed, same limitation as whichever
  prior session computed the 2026-07-30 snapshot. Both metrics are honestly
  rendered as insufficient rather than fabricated (ADR-0004) — no change
  attempted here since it needs `gh` CLI availability, not a script bug.

No test hardcodes the specific numbers (checked `tests/dora-metrics.bats` and
`tests/dora-audit-readiness.bats` — both assert structure/presence only), so this
is a pure data refresh with no code change.

`make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1390
