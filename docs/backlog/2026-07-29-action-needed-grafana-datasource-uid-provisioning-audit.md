# [Action needed] Now/next still gated; Grafana datasource-UID-to-provisioning audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#852](https://github.com/tooming/k8s-anywhere/pull/852)
(Makefile/script reference integrity audit).

## This cycle's fresh angle

A different datasource-related check than the earlier dashboard-UID
uniqueness sweep (which checked dashboards don't collide with each other):
whether the datasource `uid` values every dashboard *references*
(`"mimir"`, `"loki"`, `"tempo"`, `"pyroscope"`) actually match what
Grafana's own datasource **provisioning** config declares
(`gitops/platform/observability-grafana.yaml`'s
`datasources.datasources[].uid` fields) — a real mismatch class: if a
dashboard referenced a UID Grafana never provisions, every panel using it
would show "datasource not found" instead of data.

Confirmed: the provisioning config declares exactly `uid: mimir`,
`uid: loki`, `uid: tempo`, `uid: pyroscope` — matching every dashboard
reference checked in an earlier cycle's UID-uniqueness sweep. No mismatch.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct datasource
check (provisioning-vs-reference consistency, not just reference
uniqueness). The run continues to the next cycle per `executor.prompt.md`
STEP 8; this is not a stopping point.
