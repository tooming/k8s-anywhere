# [Action needed] Now/next still gated; container resource-limit vs. LimitRange-ceiling audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#837](https://github.com/tooming/k8s-anywhere/pull/837) (governance
LimitRange coverage recheck, near-miss caught).

## This cycle's fresh angle

A genuinely different, functional-correctness-oriented check no prior
`docs/backlog/` note has run: whether any container's own resource
`limits.cpu`/`limits.memory` across `gitops/` actually **exceeds** its own
namespace's governance `LimitRange` ceiling. This is a real admission-time
failure mode a live cluster would hit (a Pod whose container limit exceeds
its namespace's `max` is rejected outright by the LimitRange admission
controller) — distinct from anything the existing `governance.bats` presence
checks verify (those confirm a LimitRange *exists*, not that every workload
actually *fits inside* it).

- Standard-tier ceiling (17 namespaces, `gitops/governance/base/
  limitrange-standard.yaml`): `max.cpu: 2000m`, `max.memory: 4Gi`.
- Heavy-tier ceiling (`observability` only,
  `gitops/governance/observability/limitrange.yaml`): `max.cpu: 4000m`,
  `max.memory: 8Gi`.
- Swept every `memory:`/`cpu:` value under `limits:` blocks across all of
  `gitops/`: the largest real container limit found anywhere is the ArgoCD
  application-controller's `cpu: "1"` / `memory: 2Gi`
  (`infra/modules/argocd/values.yaml`) — comfortably inside the standard
  tier's `2000m`/`4Gi` ceiling. The only `4Gi`/`8Gi`/`4000m` values
  anywhere in `gitops/` are the two `LimitRange` files' own `max:` fields,
  not any workload's actual `limits:` block. No container anywhere is at
  risk of an admission-time LimitRange rejection.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct,
functional-correctness check (container limits vs. LimitRange ceilings, not
just presence-of-LimitRange), not a repeat of any prior cycle's technique.
The run continues to the next cycle per `executor.prompt.md` STEP 8; this is
not a stopping point.
