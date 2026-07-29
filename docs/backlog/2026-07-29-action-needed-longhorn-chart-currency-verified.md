# [Action needed] Now/next still gated; Longhorn chart currency verified (v1.12.x is still a pre-release, correctly not bumped)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#878](https://github.com/tooming/k8s-anywhere/pull/878) (Istio chart
currency, verified directly against the reachable GCS chart host).

## This cycle's fresh angle

`gitops/platform/longhorn.yaml` pins `targetRevision: 1.11.3`
(`https://charts.longhorn.io`, ADR-0013) — that host is unreachable from
this sandbox. `git ls-remote --tags` against `longhorn/longhorn` (the
product repo) showed a newer tag, `v1.12.0`, which at first glance looked
like a real bump candidate. Checked further before concluding anything:

- `longhorn/charts` (the actual Helm chart source) has release **branches**,
  not tags — `git ls-remote --heads` shows a `v1.12.x` branch exists.
- Fetched that branch's real `Chart.yaml` directly
  (`raw.githubusercontent.com`, reachable): `version: 1.12.1-rc2` — **a
  release candidate, not a stable release** — with `kubeVersion:
  ">=1.34.0-0"`, a much higher Kubernetes floor than the currently pinned
  `1.11.3`'s `>=1.25.0-0`.
- Fetched `v1.11.x`'s `Chart.yaml` for comparison: `version: 1.11.3` — an
  exact match for what's already pinned.

**Conclusion: `1.11.3` is genuinely the latest stable chart; no bump
available.** A version with no pinnable stable chart/image is NOT
groundable (ADR-0004) — bumping to an `-rc` tag, or one requiring a
Kubernetes version this lab may not run, would assert a posture this
session cannot verify. This also avoided a false positive that a
tag-only (`git ls-remote --tags` on the product repo, not the chart repo)
check would have produced.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) `longhorn/charts`' `v1.12.x`
branch reaching a stable (non-`-rc`) release.

This note is this cycle's honest record — a fresh component check that
caught and correctly rejected its own near-miss false positive (tag vs.
actual chart-branch pre-release state) before writing anything wrong. The
run continues to the next cycle per `executor.prompt.md` STEP 8; this is
not a stopping point.
