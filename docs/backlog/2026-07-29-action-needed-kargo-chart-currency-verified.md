# [Action needed] Now/next still gated; Kargo chart currency verified via git ls-remote (tag matches pin exactly)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#880](https://github.com/tooming/k8s-anywhere/pull/880) (Harbor chart
currency, verified via `git ls-remote`).

## This cycle's fresh angle

`gitops/platform/kargo.yaml` pins chart `1.11.0` from `ghcr.io/akuity/
kargo-charts` (OCI, ADR-0023) — not a `.github.io`/GCS host, so no chart
index to fetch, and ghcr.io anonymous token requests return `DENIED` from
this sandbox (same limitation noted for KRO earlier this run). `git
ls-remote --tags` against `akuity/kargo` (the app repo the OCI chart is
co-published from) shows `v1.11.0` is the newest tag — **exactly matching**
the current pin, so unlike the KRO case (a newer tag existed *beyond* the
pin, creating a real bump-or-hold decision this run correctly deferred),
there is no ambiguity to resolve here: the pin already sits at the latest
available tag.

**Conclusion: current, no bump available or needed.**

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
