# [Action needed] Now/next still gated; Istio ambient mesh version + sync-wave consistency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#856](https://github.com/tooming/k8s-anywhere/pull/856) (Kargo
promotion-pipeline structural consistency check).

## This cycle's fresh angle

Checked the Istio ambient mesh's four ArgoCD Applications
(`istio-base`/`istio-cni`/`istiod`/`ztunnel`, ADR-0012) — a component this
run hadn't directly inspected since the very first cycle's stranded-PR
recovery (which only touched its dashboard/scrape wiring, not the
Applications themselves):

1. **Chart version consistency** — all four pin the exact same
   `targetRevision: 1.30.3`. A mismatch across these would be a real
   functional bug (Istio's control-plane/data-plane/CNI components must run
   the same release); confirmed identical everywhere.
2. **Sync-wave ordering** — `istio-base` (wave 1) → `istio-cni` (wave 2) →
   `istiod` (wave 3) → `ztunnel` (wave 4), exactly matching
   `docs/dependency-tree.md`'s documented deployment order ("CRDs → CNI
   plugin → control plane → per-node proxy DaemonSet").

Both checks clean. No bounded, real, behavior-preserving cleanup or upgrade
qualified for a direct fix this cycle. `make ci` is unaffected (no
code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct component
(Istio ambient mesh's own Application definitions) checked for version and
ordering consistency, clean. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
