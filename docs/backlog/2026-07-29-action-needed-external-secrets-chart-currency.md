# [Action needed] Now/next still gated; External Secrets Operator chart currency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#861](https://github.com/tooming/k8s-anywhere/pull/861)
(ack-resources + Grafana chart currency recheck).

## This cycle's fresh angle

Checked External Secrets Operator's chart pin (`gitops/platform/
external-secrets.yaml`, `targetRevision: 2.8.0`) — a core always-on
component not yet directly version-checked this run — against
`external-secrets/external-secrets`'s real git tags: `v2.8.0` is the latest
tag. Already current, no bump available.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
