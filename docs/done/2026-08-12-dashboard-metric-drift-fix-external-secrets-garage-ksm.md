# Grafana dashboard metric-name drift fix — External Secrets, Garage, KSM panels silently broken

(CHARTER **Objective O5** "every always-on component has a real-metric dashboard";
CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, after the
Now/next lane was re-confirmed fully gated (six items, three sequential
Forgejo-migration items plus `verifyImages` Enforce-flip/O4 CI gate/capstone
Deployment removal all still blocked on unconfirmed standing issues #631/#633 —
re-checked directly, both still open, no new comment since 2026-08-11). Direct
continuation of PR #1155 (Cilium/Harbor/Trivy) and PR #1156 (ArgoCD/Kargo/
Argo Rollouts/Velero) — same class of bug, a third batch of dashboards audited.
No prerequisites — executor may pick up immediately.)

## What was wrong

Continued the dashboard PromQL metric-accuracy audit PR #1155/#1156 started:
resolve each component's pinned version from its `gitops/platform/*.yaml`
manifest, then clone/fetch the real upstream source at that exact tag (or its
own documented metrics reference) and check every panel's queried metric name
and labels against the actual registration code — primary source, not
assumption (ADR-0004). Checked five more dashboards this cycle (Kyverno and
Alloy came back clean — real, negative-but-honest results, no diff needed);
three had real, previously-undiscovered bugs:

1. **`grafana/dashboards/lab-external-secrets.json`** — three panels, verified
   against external-secrets v2.9.0's own source
   (`pkg/controllers/externalsecret/esmetrics/esmetrics.go`):
   - "Sync Errors (total)" queried `externalsecret_sync_calls_total{status="error"}`.
     `externalsecret_sync_calls_total` has **no `status` label at all** — sync
     attempts and sync errors are two entirely separate counters
     (`externalsecret_sync_calls_total`, `externalsecret_sync_calls_error`), not
     one counter split by a status label. This panel could never match anything.
   - "ExternalSecret sync success rate /s (by namespace)" had the identical
     nonexistent-label bug (`{status="success"}`).
   - "ExternalSecret sync duration p95 (s)" queried
     `externalsecret_sync_calls_duration_seconds_bucket` via
     `histogram_quantile()`. This metric does not exist at all — the real
     duration metric is `externalsecret_reconcile_duration`, a **Gauge**
     recording the *last* reconcile's duration in **nanoseconds**
     (`float64(time.Since(start))`, no unit conversion applied by ESO itself),
     not a Histogram — so there is no `_bucket` series and no percentile is
     computable against it.

2. **`grafana/dashboards/lab-garage.json`** — the most extensive finding: **7 of
   9 metric panels** queried metrics that either don't exist under that name or
   don't exist under any name. Verified against Garage v2.3.0's own documented
   metrics reference (`doc/book/reference-manual/monitoring.md`) plus its
   `src/block/metrics.rs` source:
   - "Bucket Count" (`garage_bucket_count`), "Total Objects"
     (`garage_object_count`), "Storage Used (GiB)" / "Storage Bytes Over Time"
     (`garage_storage_bytes`) — **Garage exposes no Prometheus metric for
     bucket count, object count, or storage bytes used, at all.** That usage
     data is only available via Garage's Admin API (JSON), not as a scraped
     metric. These four panels were structurally guaranteed to never show
     data — not a naming typo, a genuine absence.
   - "S3 API Request Rate (by handler)" queried `garage_s3_api_request_total`
     with a `handler` label. The real metric is `api_s3_request_counter` (no
     `garage_` prefix), labeled `api_endpoint`, not `handler`.
   - "S3 API Error Rate" queried `garage_s3_api_error_total`; real name
     `api_s3_error_counter`.
   - "Block Resync Queue" queried `garage_block_resync_queue_length`; real
     name `block_resync_queue_length` (no `garage_` prefix — Garage's metric
     namespace for block-manager metrics is `block_*`, not `garage_*`).
   - "Block Resync Rate (by status)" queried `garage_block_resync_total` with a
     `status` label. The real metrics are two separate, unlabeled counters —
     `block_resync_counter` (all resync attempts) and
     `block_resync_error_counter` (failed resyncs) — there is no single
     counter with a status label to split by.

3. **`grafana/dashboards/lab-ksm.json`** — a different flavor of the same
   underlying class of bug: not a wrong metric *name*, but a metric that is
   real yet **structurally unreachable by the existing scrape config**. "KSM
   Version" (`kube_state_metrics_build_info`) and "KSM Watch Total by
   Resource" (`kube_state_metrics_watch_total`) are real kube-state-metrics
   self-monitoring metrics — but the chart's `selfMonitor.enabled` defaults to
   `false` (verified against chart 8.2.0's `templates/service.yaml` /
   `templates/deployment.yaml`), which means the Service never opens a port
   for the `:8081` telemetry listener that serves them at all. Alloy's only
   KSM scrape target hits `:8080` (the main `kube_*` cluster-object-metrics
   port, which never carried these two self-metrics). These panels were
   structurally guaranteed to never show data since the dashboard was
   authored.

All bugs have shown "No data" since their dashboards were first written — not
recent regressions, the same pattern PR #1155/#1156 already found elsewhere.

## Fix

- `lab-external-secrets.json`: "Sync Errors" now queries
  `externalsecret_sync_calls_error`. "sync success rate" renamed to "sync call
  rate" and drops the nonexistent `status` filter (now shows total sync call
  volume by namespace; error volume is the adjacent panel). "sync duration
  p95" renamed to "reconcile duration, avg (ms)" and now queries
  `avg(externalsecret_reconcile_duration) / 1e6` (ns → ms; no percentile is
  possible against a Gauge, so this reports the average instead).
- `lab-garage.json`: removed the four bucket/object/storage panels outright
  (same "make the bug impossible by construction" pattern as PR #1155's SBOM
  panel and PR #1156's canary-weight panel — no real metric backs them, so
  leaving them in place with any query is dishonest). Corrected the three
  fixable panels to their real metric names/labels. Redesigned "Block Resync
  Rate" as "Block Resync Rate (attempts vs errors)" with two series
  (`block_resync_counter`, `block_resync_error_counter`) instead of a
  nonexistent `status`-labeled split. Widened it to full width and rearranged
  the stat-panel grid to fill the space the four removed panels freed —
  8 panels total now (down from 13), no gaps. Updated the dashboard's own
  "About" panel text to state plainly that Garage has no bucket/object/storage
  metric, so a future reader doesn't have to rediscover this.
- `lab-ksm.json`: no panel query changes (the queries were already correct —
  the bug was in the scrape wiring, not the dashboard). Fixed at the source:
  `observability-ksm.yaml` now sets `selfMonitor.enabled: true` (confirmed
  safe — traced the chart's full Helm template nesting: the
  `kube-rbac-proxy-telemetry` sidecar that would otherwise wrap the port in
  HTTPS+RBAC is gated on `kubeRBACProxy.enabled`, which this lab leaves at its
  `false` default, so enabling `selfMonitor` alone opens a plain-HTTP `:8081`
  Service port with no auth complexity). `observability-alloy.yaml` adds a new
  `prometheus.scrape "ksm_self"` block targeting
  `kube-state-metrics.observability.svc.cluster.local:8081`. The existing
  `allow-observability-intra-namespace` NetworkPolicy already permits this
  (broad intra-namespace allow, all ports) — updated its comment to list the
  new port for accuracy.
- Updated `docs/dependency-tree.md`'s three matching dashboard citations.
- Fixed `tests/observability.bats` (frozen monolith — updated via
  `make observability-tests-mark` per its own convention), which was asserting
  the OLD WRONG Garage metric names as correct; the External Secrets assertion
  there was already name-agnostic enough to survive unchanged (still asserts
  `externalsecret_sync_calls_total` is referenced, which remains true). Added
  two new per-scope files — `tests/observability-external-secrets.bats` and
  `tests/observability-ksm.bats` — with regression-guard coverage for the
  specific real-vs-wrong metric names/wiring found this cycle (new component
  scopes go in their own file, never appended to the frozen monolith).

## Recurrence prevention

Same as PR #1155/#1156: no existing "assert every dashboard's PromQL metric is
real" mechanical guard exists to extend (would need live-cluster metric
introspection, or a maintained per-component metric allowlist — both out of
scope for a bounded janitor fix). The new/updated `tests/*.bats` assertions
above guard against a regression back to the specific wrong strings found this
cycle — the narrowest honest guard available without a live cluster.

PR #1156 put the running total at "30 of 39 dashboards audited" before this
PR. This cycle directly audited 5 more, not previously covered by #1155/#1156
(Kyverno and Alloy — clean, no bug; External Secrets, Garage, KSM — real bugs,
fixed above), bringing the running total to 35 of 39 per that same
self-reported convention. Roughly 4 remain unchecked — a natural next cycle's
angle if this pattern keeps paying off.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration
items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631;
capstone Deployment removal on unconfirmed issue #633) — re-checked directly,
both still open, no new comment since 2026-08-11.

## ADR-0004 caveat

Every corrected metric name/wiring gap was verified against real upstream
source (GitHub raw file fetches / repo clones at the exact pinned tag, or the
component's own documented metrics reference) before any edit was applied.
The KSM `selfMonitor.enabled` fix's actual live effect (the Service opening
the port, Alloy successfully scraping it, Mimir receiving the series) is
**not** verified against a live cluster — this remote clusterless session
cannot do that — the Helm template nesting was traced by hand instead, which
is the strongest verification available without one.

## Rollback path

Revert this commit. For the KSM change specifically: reverting
`observability-ksm.yaml`'s `selfMonitor.enabled` and
`observability-alloy.yaml`'s `ksm_self` scrape block returns to the prior
(also broken, but previously-shipped) state — no data loss, ArgoCD syncs the
revert within 30s like any other gitops change.

## PR

(filled in after `gh pr create`)
