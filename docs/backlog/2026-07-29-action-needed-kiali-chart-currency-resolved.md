# [Action needed] Now/next still gated; Kiali chart currency now confirmed (previously left unverified)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#876](https://github.com/tooming/k8s-anywhere/pull/876) (Trivy
Operator chart currency, confirmed via a new `git ls-remote` technique after
its `.github.io`-hosted index was unreachable).

## This cycle's fresh angle

Applied that same new technique to a previously-open gap: earlier this run
(`docs/backlog/2026-07-29-action-needed-kiali-chart-recheck-blocked.md`,
merged PR #870), `gitops/platform/kiali.yaml`'s `targetRevision: 2.29.0` was
left unverified because `kiali.org/helm-charts/index.yaml` — the Helm repo
URL the Application actually sources from — was unreachable from this
sandbox. Rather than treat that as permanently closed, tried `git ls-remote
--tags` against the chart's real GitHub source (`kiali/helm-charts`, tag
prefix `v`) — reachable via the git protocol even though `kiali.org` itself
isn't. Result: `v2.29.0` is the newest tag in the repo — the pin is current.

**Conclusion: Kiali's chart currency gap is now resolved**, not just
documented as blocked. This confirms the git-ls-remote technique introduced
last cycle generalizes beyond `*.github.io` Pages hosts to vendor-hosted
Helm repos too, as long as the underlying chart's GitHub source repo can be
identified.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — resolving a previously-blocked
verification rather than leaving it stale. The run continues to the next
cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
