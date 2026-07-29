# [Action needed] Now/next still gated; Trivy Operator chart currency confirmed via git ls-remote (new technique)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#875](https://github.com/tooming/k8s-anywhere/pull/875) (pre-wired
`inkless-daily` Velero schedule, the follow-up flagged by this run's earlier
`observability` backup-gap RFC #873/PR #874).

## This cycle's fresh angle

`gitops/platform/trivy-operator.yaml` pins chart `0.34.0`
(`aquasecurity.github.io/helm-charts/`) — that `.github.io` host is
unreachable from this sandbox, same as `kiali.org`/`grafana.github.io`
earlier this run. Rather than leave it unverified again, tried a different
technique this time: `git ls-remote --tags` against the chart's real GitHub
source repo (`aquasecurity/helm-charts`, tag prefix `trivy-operator-`) —
that host **is** reachable (git protocol, not the `.github.io` web/Pages
host). Result: `trivy-operator-0.34.0` is the newest tag in the repo — the
pin is current. Cross-checked against ADR-0022's own citation
(`appVersion: 0.32.0`) against `aquasecurity/trivy-operator`'s own tags
(`git ls-remote`, latest `v0.32.0`) — also matches.

**Conclusion: chart and appVersion both current, no bump available.** This
also demonstrates a reusable technique for future cycles: any chart hosted
on a `*.github.io` Pages site that's unreachable here can often still be
currency-checked via `git ls-remote --tags` against the chart's real GitHub
source repo, which uses the git protocol rather than the blocked web host.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely new verification
technique (git-protocol currency check bypassing a blocked Pages host) that
came back clean. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
