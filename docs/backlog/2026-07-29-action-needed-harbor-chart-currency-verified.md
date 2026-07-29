# [Action needed] Now/next still gated; Harbor chart currency verified via git ls-remote

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#879](https://github.com/tooming/k8s-anywhere/pull/879) (Longhorn
chart currency, verified — and a pre-release false positive correctly
rejected — via the chart's real Chart.yaml).

## This cycle's fresh angle

`gitops/platform/harbor.yaml` pins `targetRevision: 1.19.1`
(`https://helm.goharbor.io`, ADR-0024) — that host is unreachable from this
sandbox. `git ls-remote --tags` against the chart's real GitHub source
(`goharbor/harbor-helm`) shows `v1.19.1` is the newest tag in the repo.

**Conclusion: current, no bump available.**

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — another component (not previously
version-checked this run) confirmed current via the git-ls-remote technique.
The run continues to the next cycle per `executor.prompt.md` STEP 8; this is
not a stopping point.
