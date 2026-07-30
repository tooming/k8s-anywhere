# [Action needed] Now/next still gated; GitLab CI/Kyverno match-scope audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Two real merged PRs this run
([#903](https://github.com/tooming/k8s-anywhere/pull/903),
[#905](https://github.com/tooming/k8s-anywhere/pull/905)), plus several honest
fallback-chain records this cycle-9 run
([#904](https://github.com/tooming/k8s-anywhere/pull/904),
[#906](https://github.com/tooming/k8s-anywhere/pull/906),
[#907](https://github.com/tooming/k8s-anywhere/pull/907),
[#909](https://github.com/tooming/k8s-anywhere/pull/909),
[#910](https://github.com/tooming/k8s-anywhere/pull/910),
[#911](https://github.com/tooming/k8s-anywhere/pull/911)), and one independent
merge from a concurrent executor session
([#908](https://github.com/tooming/k8s-anywhere/pull/908)).

## This cycle's fresh angle (clean)

1. **`.gitlab-ci.yml` job/stage graph consistency.** Verified the 2 defined
   `stages:` (`build`, `sign`) exactly match the 2 real jobs' `stage:` values,
   and `sign-image`'s `needs: [build-and-push]` references a job that
   actually exists. Clean — no dangling reference (the 3rd, not-yet-built
   `verify-rejection` stage is the intentionally-gated O4 CI item already
   tracked in ROADMAP.md, not a gap in the current file).
2. **Kyverno `ClusterPolicy` match-scope audit** — checked every policy in
   `gitops/kyverno/policies/*.yaml` for an overly broad `kinds:` selector
   (e.g. a wildcard). All 5 scope narrowly to `kinds: [Pod]`. Cross-checked
   `disallow-latest-tag.yaml` specifically against this cycle's earlier
   `:latest`-tag findings (capstone demo image, `ghcr.io/aiven/inkless`) —
   both already have explicit, well-documented `exclude.any.resources.
   namespaces` carve-outs in this exact policy, each with its own flip
   condition recorded inline. Confirms those findings were already correctly
   handled, not a new gap.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
