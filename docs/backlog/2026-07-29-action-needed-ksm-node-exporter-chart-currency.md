# [Action needed] Now/next still gated; KSM + node-exporter chart currency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#862](https://github.com/tooming/k8s-anywhere/pull/862) (External
Secrets Operator chart currency check).

## This cycle's fresh angle

Checked two more Always-on core charts not yet individually version-checked
this run (only their dashboards had been verified previously): Kube State
Metrics (`observability-ksm.yaml`, chart `8.0.0`) and Prometheus Node
Exporter (`observability-node-exporter.yaml`, chart `4.56.1`), both sourced
from `prometheus-community/helm-charts`. Checked real git tags: `8.0.0` is
the only/latest `kube-state-metrics-8.x` tag; `4.56.1` is the latest
`prometheus-node-exporter-4.x` tag. Both already current, no bump
available.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
