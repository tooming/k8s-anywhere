# Grafana dashboard metric-value drift fix — Longhorn "Healthy Volumes" panel silently broken

(CHARTER **Objective O5** "every always-on/on-demand component has a real-metric
dashboard"; CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded
cleanup 2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, after the
Now/next lane was re-confirmed fully gated (six items, unchanged, still blocked on
unconfirmed standing issues #631/#633 — re-checked directly this cycle, both still
open, no new comment since 2026-08-11). Direct continuation of the dashboard
PromQL/label metric-accuracy audit (PR #1155, #1156, #1157) — same class of bug,
a fourth pass, this time a label-*value* case mismatch rather than a wrong metric
*name*. No prerequisites — executor may pick up immediately.)

## What was wrong

Continued the dashboard metric-accuracy audit into a new batch: Longhorn, TiDB,
KEDA, Inkless (kafka-exporter), Istio, Envoy, git-sync, and cloud-control-plane
(moto/ACK/KRO). Verified each component's custom metric names and label values
against real upstream source at the pinned tag (or, for the well-known
ecosystem-standard exporters — Envoy, controller-runtime, kafka-exporter, Istio's
`pilot_xds_pushes` — against their long-stable, extensively-documented naming).
TiDB, KEDA, Inkless, Istio, Envoy, git-sync, and cloud-control-plane all came back
clean — real, negative-but-honest results.

**`grafana/dashboards/lab-longhorn.json`**'s "Healthy Volumes" panel had a real
bug: `count(longhorn_volume_robustness{robustness="Healthy"})` (Title-Case). The
real `VolumeRobustnessHealthy` constant (verified against longhorn-manager
v1.11.3 source, `k8s/pkg/apis/longhorn/v1beta2/volume.go`) is
`VolumeRobustness("healthy")` — lowercase — and the metrics collector
(`metrics_collector/volume_collector.go`'s `collectVolumeRobustness`) emits it
verbatim via `string(r)` with no case transform. `{robustness="Healthy"}` could
never match any real series — this panel has shown "not deployed"/no data
indistinguishably from Longhorn genuinely being down since the dashboard was
authored, not a recent regression. Same case-mismatch class of bug as PR #1155's
Trivy CVE-severity-label fix (`severity="CRITICAL"` vs the real Title-Case
`"Critical"` there — here it's the reverse direction, dashboard used Title-Case
against a real lowercase value).

The dashboard's sibling "Attached Volumes" panel (`{state="attached"}`) was
already correct — verified the real `VolumeStateAttached = VolumeState("attached")`
constant matches exactly, lowercase, no bug there.

## Fix

`lab-longhorn.json`: `robustness="Healthy"` → `robustness="healthy"`. Added two
regression-guard tests to `tests/longhorn.bats` (existing dedicated file, not the
frozen `tests/observability.bats` monolith): asserts the real lowercase value is
present, and that the wrong Title-Case value is absent.

## Recurrence prevention

Same as PR #1155/#1156/#1157: no existing "assert every dashboard's PromQL
metric/label value is real" mechanical guard exists to extend (would need
live-cluster metric introspection or a maintained per-component metric+label
allowlist — out of scope for a bounded janitor fix). The new `tests/longhorn.bats`
assertions guard against a regression back to the specific wrong string found
this cycle.

This cycle directly audited 8 more dashboards (Longhorn — 1 real bug, fixed;
TiDB, KEDA, Inkless, Istio, Envoy, git-sync, cloud-control-plane — clean),
continuing from the running "35 of 39" total PR #1157 left off, bringing it to
roughly 43 dashboard-component-checks across all four PRs (some totals overlap
where a dashboard covers more than one component, e.g. cloud-control-plane
covers three). A handful of the 39 dashboard files remain unchecked — a natural
next cycle's angle if this pattern keeps paying off.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration
items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631;
capstone Deployment removal on unconfirmed issue #633) — re-checked directly,
both still open, no new comment since 2026-08-11.

## ADR-0004 caveat

The corrected label value was verified against real upstream source (a GitHub
clone at the exact pinned tag `v1.11.3`) before editing. This remote clusterless
session cannot verify the panel actually renders real data against a live
Longhorn deployment — Longhorn is itself on-demand (`make longhorn-up`), so the
panel legitimately shows "not deployed" until then regardless of this fix.

## Rollback path

Revert this commit — a single-line JSON value change plus two additive test
assertions, no other surface affected.

## PR

(filled in after PR creation)
