# [Action needed] Now/next still gated; cert-manager/KEDA sync-wave dependency chain check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## Note: a concurrent session is active

This cycle found PR [#865](https://github.com/tooming/k8s-anywhere/pull/865)
(`sync/docs-drift-2026-W31`, a different session, adding cert-manager/KEDA
nodes to `docs/dependency-tree.md`'s diagram) open with checks still
pending — a run in progress, not stranded, per `executor.prompt.md` STEP 1b.
Left it alone and picked a fresh angle this cycle that doesn't touch
`docs/dependency-tree.md`, to avoid any file-level collision.

## What this cycle already did

Merged [#864](https://github.com/tooming/k8s-anywhere/pull/864)
(demo/data-layer image currency sweep).

## This cycle's fresh angle

Verified the cert-manager/KEDA sync-wave dependency chain is internally
consistent: `cert-manager-extras` (wave 0, namespace/PSA labels) →
`cert-manager` (wave 1, controller) → `cert-manager-root-ca` (wave 5,
`ClusterIssuer`, needs the controller's CRDs ready) → `lab-gateway-
certificate` (wave 6, needs the `ClusterIssuer`) and `keda` (also wave 6,
its admission webhook TLS is wired to the same `k8s-lab-ca` issuer, per
CHARTER's own KEDA description). Both wave-6 consumers correctly sit after
wave 5's issuer. No ordering defect found.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle (outside PR #865's own in-progress scope). `make ci`
is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) PR #865 finishing its own
in-progress cycle (a future cycle should check whether it needs the STEP 1b
stranded-PR recovery if it goes green with no self-review).

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
