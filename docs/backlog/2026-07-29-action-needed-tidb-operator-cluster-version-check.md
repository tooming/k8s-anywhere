# [Action needed] Now/next still gated; TiDB Operator/Cluster version-line currency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#857](https://github.com/tooming/k8s-anywhere/pull/857) (Istio
ambient mesh version + sync-wave consistency check).

## This cycle's fresh angle

Checked TiDB's two on-demand components, following the same pattern as the
Istio check last cycle: `tidb-operator` (chart `1.6.5`) and the
`TidbCluster` CR it manages (`gitops/tidb/tidb-cluster.yaml`, pinned
`version: "v8.5.7"`). Verified both against live upstream tags:

- `pingcap/tidb-operator`'s latest `1.6.x` tag is `v1.6.5` — already
  current.
- `pingcap/tidb`'s latest stable `8.5.x` tag is `v8.5.7` — already current
  (ignoring dated/dev-suffixed nightly tags like `v8.5.7-20260716-...`,
  which aren't real releases).

Both already at the latest patch on their respective pinned lines. No bump
available, no version-compatibility gap.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — TiDB's on-demand component pins
re-verified live and confirmed current. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
