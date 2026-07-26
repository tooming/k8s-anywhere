# Planner note — 2026-07-26 — capstone-pipeline governance LimitRange gap

## What prompted this

This run's executor cycle was working the STEP 6b fallback chain (Now/next fully
gated on standing issues #631/#632/#633) and had already shipped two real fixes via
systematic cross-referencing of every PSA-labeled namespace against the ArgoCD
appsets that are supposed to cover them (`docs/dependency-tree.md`'s missing
`tidb-admin-extras` row, and the dead `kiali-governance` entry — see PRs #747 and
#750). Running the same cross-reference one more time against
`gitops/platform/governance-appset.yaml` surfaced a third gap, but this one is an
*addition* (new namespace + LimitRange to pre-create on a live cluster), not a
removal — which is executor/architect territory, not something a janitor-style
cleanup should decide unilaterally. Filing it as a proper ROADMAP item instead.

## The gap

Of the 29 real PSA-labeled namespaces in `gitops/`, 23 are eligible for the RFC
#294 standard-tier governance LimitRange (29 minus the 5 documented on-demand-heavy
exclusions — `tidb`, `tidb-admin`, `longhorn-system`, `istio-system`, `inkless` —
minus the 1 ADR-0024 `artifactory` exclusion). Only 22 currently have a governance
entry (after this run's `kiali-governance` removal, which was dead config pointing
at a namespace that never exists). The 23rd, missing entry: `capstone-pipeline`
(the Kargo Project/Warehouse/Stage namespace, `gitops/kargo-project/namespace.yaml`,
PSA `restricted`).

Unlike `kiali`, `capstone-pipeline` is a real namespace that really gets created
(by the on-demand `kargo-project` Application, paired with `make kargo-up`) — it
just never got a governance LimitRange leaf. It isn't in either documented
exclusion list, and ADR-0017's own PSA row for it already argues for exactly this
kind of defense-in-depth floor ("ensuring any future pod admitted here is hardened
by default").

## Added to ROADMAP.md

One new 🟢 item in *Now / next*, immediately after the existing (gated) "Remove
legacy capstone Deployment" item: **`capstone-pipeline` governance LimitRange — RFC
#294 fan-out completion**. No RFC needed — this purely extends an already-decided,
already-implemented-21-other-times pattern to one more consistent case; no new
architectural decision is being made. Tagged with an explicit executor note that
this adds new always-on cluster state (unlike a pure doc/test cleanup), mirroring
the same pre-creation pattern `kargo-extras` already uses for the `kargo` namespace
itself.

## Not touched

No other ROADMAP items changed. No issues groomed this run (intake queue is empty —
the only open issues are the three standing `[Action required]` confirmation
trackers, which are not groomable work).
