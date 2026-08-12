# Grafana dashboard metric-name drift fix — Alloy remote-write panel + Grafana self-monitoring panels

(CHARTER **Objective O5** "every always-on component has a real-metric dashboard";
CHARTER **Core Values** §"Real observability only" (ADR-0004); JANITOR-fallback bounded
cleanup 2026-08-12, reached via `executor.prompt.md` STEP 6b — the Now/next lane was
re-confirmed fully gated (six items, unchanged, still blocked on unconfirmed standing
issues #631/#633), and this cycle's own attempts at the PLANNER (no groomable intake, no
unpromoted 🟢 item to refill Now/next), ARCHITECT (no un-RFC'd 🟡 item), UPGRADE-DRAFTER
(the only three candidates found — Valkey 8.1.9, Cilium 1.19.6, Longhorn 1.12.0 — are all
blocked by binding ADR-0018/ADR-0014/ADR-0013 Re-evaluation-log hold decisions with unmet
flip conditions; see "What was ruled out" below), DOC-DRIFT-AUTHOR (`make readme-check` +
`make lab-ui-check` both clean, no broken Application source paths), and TRIAGER (both
open issues are already correctly labeled standing `[Action required]` trackers, not
untriaged intake) all came up empty — fell through to JANITOR. Direct continuation of the
dashboard PromQL/label metric-accuracy audit (PRs #1155, #1156, #1157, #1158), a 5th pass.
No prerequisites — executor may pick up immediately.)

## What was ruled out first (UPGRADE-DRAFTER role)

A background investigation walked every gitops/infra pinned dependency not recently
touched, checking real upstream tags via `git ls-remote`. Three minor-version bumps
looked live at first pass — Valkey `8.0.10-alpine` → `8.1.9-alpine`, Cilium `1.18.12` →
`1.19.6`, Longhorn `1.11.3` → `1.12.0` — but each is governed by its ADR's own
**Re-evaluation log**, not just the ADR's primary Decision section:

- **ADR-0018** (Valkey): the 2026-07-20 and 2026-07-22 entries explicitly decided to hold
  at the `8.0.x` line, with a stated flip condition — "a CVE or critical-bug advisory is
  disclosed against the `8.0.x` line that `8.1.x` (or later) fixes, OR a concrete
  lab-teaching need emerges for an `8.1`+-only feature." No such CVE exists (the current
  `8.0.10` pin already carries every known fix).
- **ADR-0014** (Cilium): the 2026-07-30 entry's flip condition is "revisit when `1.18.x`
  itself reaches end-of-support... or a CVE lands against `1.18.12` specifically." Neither
  has fired.
- **ADR-0013** (Longhorn): the 2026-07-18 entry deliberately holds one minor line behind
  `1.12.x` (V2 Data Engine GA — too big a behavioral surface for a routine bump); the
  2026-07-28 re-check confirmed the same flip condition (line EOL or a named CVE) still
  hasn't fired.

Bumping any of the three would have silently overridden a binding, reasoned architect
decision — exactly what `upgrade-drafter.prompt.md` STEP 1 says to skip ("If an ADR pins
a version, that pin is binding: skip that source"). No actionable upgrade this cycle.

## What was wrong

Continued the dashboard metric-accuracy audit into a new batch: Alloy, cert-manager,
Grafana, Kyverno, Loki, Mimir, Tempo, Vault. Verified each component's metric names
against real upstream source at the pinned tag. cert-manager, Kyverno, Loki, Mimir,
Tempo, and Vault all came back clean — real, negative-but-honest results. Also personally
audited the other 13 dashboards not covered by this batch (lab-capstone, lab-data-demo,
lab-demo, lab-logs, lab-node-exporter, lab-profiles, lab-pyroscope, lab-rabbitmq,
lab-s3manager, lab-traces, lab-valkey, stack-health, tidb-demo) — all clean, completing a
full sweep of every one of the 39 dashboard files in the repo across five PRs.

**`grafana/dashboards/lab-alloy.json`**'s "Remote write bytes /s (to Mimir)" panel queried
`rate(prometheus_remote_storage_sent_bytes_total{job="alloy"}[5m])`. No metric named
`prometheus_remote_storage_sent_bytes_total` exists anywhere in `prometheus/prometheus`
(verified against the exact vendored version Alloy `v1.18.0` ships, `v0.312.0`, per its
`go.mod`) — `storage/remote/queue_manager.go` + `storage/remote/storage.go` register
`Namespace: "prometheus"`, `Subsystem: "remote_storage"`, `Name: "bytes_total"`, i.e. the
real metric is `prometheus_remote_storage_bytes_total`. This panel could never show data
since the dashboard was authored.

**`grafana/dashboards/lab-grafana.json`** had two issues in its "Users & activity" row:
- "Active users" queried `sum by (username) (rate(grafana_authenticated_user_requests{job="grafana"}[5m]))`.
  `grafana_authenticated_user_requests` does not exist anywhere in `grafana/grafana`
  `v13.0.5` (exhaustive grep of every `.go` file for the string returns zero hits) — a
  fabricated metric name. The real gauge for this purpose is `grafana_stat_active_users`
  (`pkg/infra/metrics/metrics.go`: `Namespace: "grafana"`, `Name: "stat_active_users"`,
  a bare `prometheus.Gauge` with no labels — Grafana OSS does not expose a per-username
  breakdown at all, so the panel's `by (username)`/`rate()` shape was never achievable
  against any real metric, not just this fabricated one).
- "Login rate" grouped `sum by (handler) (rate(grafana_api_login_post_total{job="grafana"}[5m]))`.
  `grafana_api_login_post_total` is real (`pkg/infra/metrics/metrics.go`'s `MApiLoginPost`),
  but it's a bare, unlabeled `prometheus.Counter` (`metricutil.NewCounterStartingAtZero`,
  incremented via a plain `.Inc()` at `pkg/api/login.go:261`) — no `handler` label exists.
  `by (handler)` didn't break the query (grouping by a nonexistent label is a harmless
  no-op), but it implied a per-handler breakdown the metric can never provide.

## Fix

`lab-alloy.json`: `prometheus_remote_storage_sent_bytes_total` →
`prometheus_remote_storage_bytes_total`. Also corrected the same stale metric name in
`docs/dependency-tree.md`'s Alloy dashboard row.

`lab-grafana.json`: "Active users" panel now queries `grafana_stat_active_users{job="grafana"}`
directly (a gauge, so no `rate()`/`by()` needed — unit changed from `reqps` to `short` to
match); "Login rate" panel drops the `by (handler)` grouping, querying
`sum(rate(grafana_api_login_post_total{job="grafana"}[5m]))` with a flat `logins/s` legend.

New `tests/observability-alloy.bats` (new file — `tests/observability.bats` is frozen)
and two new assertions in the existing `tests/observability-grafana.bats`: each asserts
the real metric name is present and the wrong/fabricated one is absent, plus a guard that
the login-rate panel no longer groups by the nonexistent `handler` label.

## Recurrence prevention

Same as PRs #1155/#1156/#1157/#1158: no existing "assert every dashboard's PromQL
metric/label value is real" mechanical guard exists to extend (would need live-cluster
metric introspection or a maintained per-component metric+label allowlist — out of scope
for a bounded janitor fix). The new bats assertions guard against a regression back to
the specific wrong strings found this cycle.

This cycle directly audited the last 8 unaudited dashboards (Alloy — 1 real bug, fixed;
Grafana — 2 real bugs, fixed; cert-manager, Kyverno, Loki, Mimir, Tempo, Vault — clean)
plus personally re-confirmed the other 13 dashboards clean, completing a full pass over
every one of the repo's 39 dashboard files across five PRs (#1155, #1156, #1157, #1158,
and this one) since 2026-08-12 — 6 real bugs found and fixed total.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration items;
`verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone Deployment
removal on unconfirmed issue #633) — re-checked directly, both still open, no new comment
since 2026-08-11.

## ADR-0004 caveat

Both corrected metric names were verified against real upstream source (fetched at the
exact pinned tag/version) before editing. This remote clusterless session cannot verify
either panel actually renders real data against a live Alloy/Grafana deployment — both
are always-on and already running, so the panels should populate on the next real scrape
once this fix syncs, but that live confirmation is out of scope for a clusterless session.

## Rollback path

Revert this commit — JSON metric-name/query value changes plus additive test assertions
and one doc-string correction, no other surface affected.

## PR

(filled in after PR creation)
