# [Action needed] Now/next still gated; Kiali chart recheck blocked (host unreachable), concurrent session noted

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## Note: a concurrent session is active

PR [#867](https://github.com/tooming/k8s-anywhere/pull/867) (`chore/
hook-scripts-coverage-freeze`, a different session, janitor-flavored
mechanical-guard fix for `tests/hook-scripts-coverage.bats`) is open with a
fresh `[self-review]` comment and `self-reviewed` label already posted
(within the last minute) — an active run mid-flow, not stranded. Left it
alone and avoided any file it touches (`tests/hook-scripts-coverage.bats`,
its new check/hook scripts, `Makefile`, `.github/workflows/ci.yml`,
`.claude/settings.json`) this cycle.

## What this cycle already did

Merged [#868](https://github.com/tooming/k8s-anywhere/pull/868) (docs/done
coverage completeness check).

## This cycle's fresh angle

Attempted to re-verify Kiali's chart pin (`gitops/platform/kiali.yaml`,
`targetRevision: 2.29.0`, set by the same-day `arch/adr-0012-kiali-
chart-index-audit` PR) directly against `kiali.org/helm-charts/index.yaml`
— that host is unreachable from this sandbox (connection failure). Left
unverified rather than guessed; the recent same-day architect audit is the
best available evidence of currency.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle (outside PR #867's own in-progress scope). `make ci`
is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) `kiali.org` becoming reachable
from a future sandbox for a direct re-check.

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
