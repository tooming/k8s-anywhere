# [Action needed] Now/next still gated; ack-resources + Grafana chart currency recheck

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#860](https://github.com/tooming/k8s-anywhere/pull/860) (broader
version recheck after the ack-s3 upgrade).

## This cycle's fresh angle

Two follow-ups from the ack-s3 upgrade success:

1. **`ack-resources.yaml`** — checked whether this sibling Application (the
   actual `Bucket` CR instances, separate from the `ack-s3` controller
   itself) has its own external version to verify. It doesn't: `repoURL` is
   this repo's own GitLab mirror on `main` (self-referential, plain
   manifests) — the same shape as Mimir/Loki/Tempo/`ack-resources`' sibling
   `data-demo`, not an external chart. No version to check.
2. **Grafana Helm chart currency** (distinct from the `image.tag` override,
   which is separately tracked and already current at `13.0.3`) — the
   chart itself is pinned `12.10.0`, already bumped from `12.8.1` in a
   recent merged `upgrade/*` PR per this run's own earlier findings. Tried
   to re-verify directly against `grafana.github.io/helm-charts/index.yaml`
   but that GitHub Pages host is unreachable from this sandbox (connection
   failure). Left unverified rather than guessed — the recent merged bump
   is the best available evidence of currency this cycle.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) `grafana.github.io` becoming
reachable from a future sandbox, so the Grafana chart version can be
re-verified directly rather than relying on the last known-current bump.

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
