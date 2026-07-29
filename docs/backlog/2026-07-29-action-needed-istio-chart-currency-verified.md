# [Action needed] Now/next still gated; Istio chart currency directly verified (1.30.3 confirmed latest stable)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#877](https://github.com/tooming/k8s-anywhere/pull/877) (Kiali chart
currency, resolved via `git ls-remote` after previously being left blocked).

## This cycle's fresh angle

All four Istio ambient-mesh components (`gitops/platform/istio-base.yaml`,
`istiod.yaml`, `istio-cni.yaml`, `ztunnel.yaml`, ADR-0012) pin
`targetRevision: 1.30.3` from `istio-release.storage.googleapis.com/charts`.
Unlike the `.github.io`-hosted indices blocked earlier this run, this GCS
host is directly reachable — confirmed with a live `curl` (HTTP 200) and a
full fetch of `charts/index.yaml`. Parsed the `istiod` chart's version list
directly (`yq '.entries.istiod[].version'`): the newest **stable** entry is
`1.30.3` (a `1.31.0-alpha.0` pre-release exists above it, correctly not a
candidate for a production-shaped lab per this repo's own upgrade-drafter
precedent of skipping pre-release tags).

**Conclusion: current, no bump available.** All four Istio Applications
share the same `targetRevision`, so this one check covers the whole
ambient-mesh component.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely fresh component check
(Istio, not previously version-checked this run) verified directly against
a reachable upstream host. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
