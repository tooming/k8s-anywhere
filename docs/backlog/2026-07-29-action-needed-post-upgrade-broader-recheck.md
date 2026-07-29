# [Action needed] Now/next still gated; broader version recheck after the ack-s3 upgrade — nothing else found

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#859](https://github.com/tooming/k8s-anywhere/pull/859) — a real,
verified `upgrade(ack-s3): 1.8.1 → 1.8.2` (this run's first genuine version
bump, found by directly querying the OCI registry's own tags API rather
than trusting a git tag alone).

## This cycle's fresh angle

Followed up on that success by applying the same rigor to nearby
components:

- Searched for any other `gitops/` source pointed at `public.ecr.aws` (the
  same OCI registry `ack-s3` uses) — **only `ack-s3` uses it**, so there was
  no second component to check with the identical technique.
- Re-checked **Velero** (chart `12.1.0`) and **Argo Rollouts** (chart
  `2.41.1`) against `vmware-tanzu/helm-charts`'s and `argoproj/argo-helm`'s
  real tag lists directly — both already at the latest tag on their
  pinned line. No bump available for either.
- Attempted the same for Kyverno's chart tags, but the repo's tag naming
  didn't match a simple pattern search; not pursued further this cycle
  rather than guess at a false result — the architect's prior audit (PR
  #830, same day) already verified Kyverno chart `3.8.2` maps to the
  CVE-patched `appVersion v1.18.2` via a different, direct method
  (fetching the chart's own `Chart.yaml` at the version tag), so this
  isn't an unverified gap, just a technique that didn't transfer cleanly.

No further bounded, real upgrade qualified for a direct fix this cycle.
`make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — following up on a real fix with a
broader sweep for more of the same, finding nothing further this time. The
run continues to the next cycle per `executor.prompt.md` STEP 8; this is
not a stopping point.
