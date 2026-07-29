# [Action needed] Now/next still gated; GitLab CI tooling currency + moto ambiguity resolved

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#835](https://github.com/tooming/k8s-anywhere/pull/835) (KRO 0.9.3
found but held back, unverifiable).

## This cycle's fresh angle

Two pieces of unfinished business, both closed out this cycle:

1. **moto, resolved.** The prior cycle's note flagged moto's Docker Hub
   `-last_updated` ordering as inconclusive. Re-ran with a proper
   `git ls-remote --tags --refs https://github.com/getmoto/moto` +
   `sort -V`: the real latest stable release is `5.2.2` — exactly what's
   pinned (`gitops/moto/deployment.yaml`). No bump needed; ambiguity closed.

2. **GitLab CI tooling currency** (`.gitlab-ci.yml`, the capstone pipeline —
   a distinct file no prior sweep note names): checked its two pinned
   external images.
   - `image: docker:29` — Docker Hub's `library/docker` tag list shows `29`
     is the only pure-numeric major tag present; already current.
   - `image: bitnami/cosign@sha256:db4d480f96235bca0433be791ea156cf51c3c7b62874618d8fcacecc86555aee`
     (`sign-image` job) — queried Docker Hub's tags API for `bitnami/cosign`
     directly: the `latest` tag's digest is
     `sha256:db4d480f96235bca0433be791ea156cf51c3c7b62874618d8fcacecc86555aee`
     — an **exact match** to the pinned digest. The image is pinned by
     digest (maximally reproducible) and that digest is literally today's
     `latest` build. Already current; nothing to bump.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) GHCR reachability from this sandbox
improving, so the still-open KRO `0.9.3` question from the immediately prior
cycle's note can finally be resolved.

This note is this cycle's honest record — closes an ambiguity the prior
cycle left open (moto) and checks a file (`.gitlab-ci.yml`) no prior sweep
note has covered. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
