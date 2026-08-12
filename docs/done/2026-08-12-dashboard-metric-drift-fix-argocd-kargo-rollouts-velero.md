# Grafana dashboard metric-name drift fix — ArgoCD, Kargo, Argo Rollouts, Velero panels silently broken

(CHARTER **Objective O5** "every always-on component has a real-metric dashboard";
CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 26th
cycle, after the Now/next lane was re-confirmed fully gated. **No prerequisites —
executor may pick up immediately.** Direct continuation of PR #1155's fix
(Cilium/Harbor/Trivy) — same class of bug, a second batch of dashboards audited.**)

## What was wrong

An Explore sub-agent continued the dashboard PromQL metric-accuracy audit PR #1155
started, checking 9 more dashboards (of 39 total) by resolving each component's
pinned version from its `gitops/platform/*.yaml` manifest, then cloning/fetching the
real upstream source at that exact tag and grepping the actual metric-registration
code (`prometheus.NewCounterVec`/`NewGaugeVec`/`NewHistogramVec` calls) — primary
source, not documentation. I independently re-verified two of the four findings via
direct `raw.githubusercontent.com` fetches before touching anything (ADR-0004):

1. **`grafana/dashboards/lab-argocd.json`**, "Reconcile duration heatmap" panel —
   queried `argocd_app_reconcile_duration_seconds_bucket`. Confirmed against ArgoCD's
   own `controller/metrics/metrics.go` at tag `v3.5.0` (this lab's pinned appVersion):
   no such metric exists. The real HistogramVec is named `argocd_app_reconcile`
   (auto-generating the `_bucket`/`_sum`/`_count` suffixes) — the real bucket series
   is `argocd_app_reconcile_bucket`.
2. **`grafana/dashboards/lab-kargo.json`**, "Freight creation rate /s" panel — queried
   `controller_runtime_reconcile_total{controller=~"freight.*"}`. At pinned Kargo
   `v1.11.1` there is no Freight reconciler at all — `pkg/controller/freight/`
   contains only a helper file, no registered controller. Freight objects are
   produced by the Warehouse controller instead. This panel duplicated the
   dashboard's own pre-existing, correctly-implemented "Warehouse reconcile rate /s"
   panel in intent, so it was removed rather than renamed into a second copy of the
   same panel.
3. **`grafana/dashboards/lab-argo-rollouts.json`**, "Active Canary Weight (%)" panel
   — queried `rollout_canary_weight`. At pinned chart `2.41.1` (appVersion `v1.9.1`),
   no such metric is defined anywhere in `controller/metrics/prommetrics.go` (the
   sole file registering all `rollout_*` metrics) — a full-repo grep for
   `canary_weight` found zero hits. No metric currently exposes a canary-weight
   percentage; the panel was structurally guaranteed to never show data, not merely
   pending an active canary.
4. **`grafana/dashboards/lab-velero.json`**, "Restore Failed (total)" panel —
   queried `velero_restore_failure_total`. Confirmed against Velero's own
   `pkg/metrics/metrics.go` at tag `v1.18.1` (this lab's pinned appVersion): the real
   constant is `restoreFailedTotal = "restore_failed_total"`, giving the real metric
   `velero_restore_failed_total` (singular "failed", not "failure").

All four have shown "No data" since their dashboards were first authored — not a
recent regression, the same pattern PR #1155 already found in Cilium/Harbor/Trivy.

## Fix

- `lab-argocd.json`: corrected the metric name.
- `lab-kargo.json`: removed the redundant/broken "Freight creation rate" panel
  (widened the "Stage reconcile rate /s" panel to fill the freed grid space); the
  dashboard's existing, correct "Warehouse reconcile rate /s" panel already covers
  the real signal (Warehouse produces Freight).
- `lab-argo-rollouts.json`: removed the "Active Canary Weight (%)" panel — no real
  metric backs it, same "make the bug impossible by construction" pattern as PR
  #1155's SBOM-panel removal.
- `lab-velero.json`: corrected the metric name.
- Updated `docs/dependency-tree.md`'s three matching stale citations to match.
- Fixed `tests/observability.bats` (frozen monolith — updated via
  `make observability-tests-mark` per its own convention) and
  `tests/argo-rollouts.bats`, which were asserting the OLD WRONG metric names as
  correct. Added new regression-guard tests to `tests/kargo.bats` and
  `tests/velero.bats`, which had no prior coverage for these specific metrics.

## Recurrence prevention

Same as PR #1155: no existing "assert every dashboard's PromQL metric is real"
mechanical guard exists to extend (would need live-cluster metric introspection or a
maintained per-component metric allowlist), so this class of bug isn't fully
guardable without a live cluster — out of scope for a bounded janitor fix. The
`tests/*.bats` assertions above guard against a regression back to the specific
wrong strings found this cycle, the narrowest honest guard available.

30 of 39 dashboards have now been audited across PR #1155 and this PR (8 clean, 6
with real bugs now fixed across the two PRs); 9 remain unchecked — a natural next
cycle's angle if this pattern keeps paying off.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration items;
`verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone
Deployment removal on unconfirmed issue #633) — re-checked directly, both still open,
no new comment since 2026-08-11.

## ADR-0004 caveat

Every corrected metric name was verified against real upstream source (GitHub raw
file fetches / repo clones at the exact pinned tag) by the investigating sub-agent;
I independently re-verified the ArgoCD and Velero findings myself before applying
any edit.

## Rollback path

Revert this commit. The bats test changes are additive/corrective assertions with no
effect outside their own test files.

## PR

https://github.com/tooming/k8s-anywhere/pull/1156
