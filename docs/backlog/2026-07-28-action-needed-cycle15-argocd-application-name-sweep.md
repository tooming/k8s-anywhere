# [Action needed] Now/next still gated; ArgoCD Application-name duplication sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped fourteen real, merged deliverables (PRs
#789, #790, #792–#803), including two live-cluster bugfixes (#796, #797).

This cycle scanned all 82 ArgoCD `Application` manifests across `gitops/` for duplicate
`metadata.name` values (a real, ArgoCD-enforced uniqueness constraint within a single
ArgoCD instance/namespace — a collision would cause one Application to silently overwrite
or fight the other). One apparent duplicate found: `root` is used by both
`gitops/bootstrap/root-app.yaml` (the primary app-of-apps) and
`gitops/bluegreen/green-root.yaml`. Verified this is intentional, not a bug: the latter is
the blue/green DR drill's app-of-apps, planted on a **separate, independently-created
green cluster's own ArgoCD instance** (per `make dr-bluegreen`) — it deliberately mirrors
the primary bootstrap pattern (same name, same `directory`-based planting technique) on a
cluster that never coexists with the primary one under the same ArgoCD, so there is no
real naming collision. The file's own header comment already documents this design
("app-of-apps planted... on the GREEN cluster's ArgoCD").

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
