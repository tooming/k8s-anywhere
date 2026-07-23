# [Action needed] Now/next still gated; Kargo + O3/O6 budget + DORA-doc checks also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments.

## This cycle's fresh angle

Four small, distinct checks not yet covered by this run's earlier cycles:

1. **Kargo** (`ghcr.io/akuity/kargo-charts`, pinned `1.10.9`) — checked
   against the real `akuity/kargo` source repo's git tags (the OCI chart
   registry itself can't be probed anonymously, same limitation this repo's
   own `helm-chart-pin-check.sh` already documents): `1.10.9` is the newest
   tag. Current.
2. **O3/O6 budget constants** — `scripts/dr-restore.sh`'s `BUDGET_S=600` and
   `scripts/capstone-demo.sh`'s `BUDGET_S=900` both match CHARTER's stated
   thresholds (O3: "under 10 minutes", O6: "under 15 min") exactly. No drift.
3. **`docs/dora-metrics.md` staleness** — last regenerated 2026-07-21, two
   days stale, with `Lead time for changes` and `Time to restore service`
   both reading "insufficient data (gh CLI or jq not available)". Checked
   whether this session could regenerate a fresher snapshot: `jq` is present
   here, but the `gh` CLI is not (this remote environment uses GitHub MCP
   tools instead, per this session's own operating constraints) — re-running
   `make dora-metrics` from this session would hit the identical "insufficient
   data" branch, not a fresher result. This is the script's own documented,
   ADR-0004-compliant graceful-degradation behavior (fail to "insufficient
   data," never fabricate), not a bug — correctly not touched.
4. **Re-confirmed no new GitHub issues, no `docs/roadmap/incoming/` files,
   no open PRs** since the last check this cycle-chain.

## Prior cycles this run

PR #690 (ArgoCD chart bump — real currency gap fixed), PR #691 (upgrade-drafter
scope fix — prevents that class of miss recurring), PR #692 (CI-tooling +
Pyroscope-hold sweep), PR #693 (O2 namespace-coverage audit). All four
substantive, all merged.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue; (d) a
`gh`-CLI-capable environment to regenerate a fuller `docs/dora-metrics.md`
snapshot (not blocking — O7's `make ci` presence check doesn't require full
data, and the current snapshot is honest, not fabricated).

This note is this cycle's honest record — a genuinely different, real check
each of five cycles this run, not repeated churn. The run continues to the
next cycle per `executor.prompt.md` STEP 8.
