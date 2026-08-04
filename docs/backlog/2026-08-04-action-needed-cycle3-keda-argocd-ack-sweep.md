# [Action needed] Now/next gated again after this run's Kiali cycle; four fresh lenses came up clean

## What's blocked

ROADMAP.md's *Now / next* lane is back to the same 3 unchecked `[ ]` items,
all still gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle (fetched both issues' comment threads directly): both still open. The
most recent comments on each (earlier today) describe an in-progress GitLab
Runner setup, but no completed end-to-end confirmation yet.

## What this run already did

Two real merged PRs so far this run:
[#969](https://github.com/tooming/k8s-anywhere/pull/969) (planner-fallback:
found a real, CVE-backed Kiali chart delta via a fresh non-checklist-component
sweep, added it to Now/next) and
[#970](https://github.com/tooming/k8s-anywhere/pull/970) (executor: built that
item — `kiali-server` chart `2.29.0` → `2.30.0`, three named CVE fixes in
Kiali's bundled frontend deps).

## This cycle's fresh angles (not repeats)

Four lenses not yet used this run, tried back-to-back after the Kiali item
merged and the lane went dry again — deliberately continuing yesterday's
"components not on the architect's fixed checklist" angle rather than
re-running the identical 17-component sweep from 2026-08-03:

1. **KEDA** (`2.20.2` pinned) — last cycle's planner note left this as an open
   follow-up (couldn't enumerate the chart repo's tag scheme cleanly at the
   time). Cloned `github.com/kedacore/charts` directly this cycle and filtered
   tags to the `v2.x.x` pattern (the repo also carries unrelated
   `keda-add-ons-http-*` tags that a loose grep picks up): newest is `v2.20.2`
   — exactly the current pin. No gap; last cycle's deferred item is now
   resolved clean.
2. **GitHub Actions versions** (`.github/workflows/*.yml`) — `actions/checkout
   v7.0.1`, `actions/cache v6.1.0`, `hashicorp/setup-terraform v4.0.1`,
   `actions/github-script v9.0.0` (from the RFC #611 major-bump grooming).
   Checked each directly against its real GitHub tags: all four are still the
   newest stable tag in their line. No gap.
3. **The recurring `infra/modules/argocd/values.yaml` `image.tag: latest`
   TODO** — re-verified live against the real `argoproj/argo-cd` repo (not
   training knowledge): the `expose-appset-ui` commit (#26666) is still only
   reachable from `v3.5.0-rc1/-rc2/-rc3` (pre-releases), not yet in any stable
   tag (`v3.4.6` is newest stable). Also confirmed the ArgoCD chart pin itself
   (`argo-cd-10.2.2`, bumped by this run's earlier `upgrade/*` cycle) already
   tracks `appVersion: v3.4.6` — fully current. The TODO's condition is
   genuinely still unmet; not a stale/forgotten TODO, same conclusion as every
   prior recheck (2026-07-21, -24, -28, -29, -31).
4. **ACK S3 controller** (`gitops/platform/ack-s3.yaml`, chart `s3-chart`
   `1.8.2`, not on the architect's fixed checklist) — checked directly against
   `github.com/aws-controllers-k8s/s3-controller`'s real tags: `v1.8.2` is the
   newest stable release. No gap.

All four came up genuinely clean — real, verified checks (ADR-0004), not
assumed from training knowledge or repeated without a fresh angle.

## Assessment

Between yesterday's 17-component + Harbor sweep, this run's earlier
cert-manager/Kargo/Kiali/KEDA check (which found and shipped the one real
Kiali delta), and this cycle's KEDA-follow-up + GitHub Actions + ArgoCD-TODO +
ACK sweep, the dependency-currency search space is now very thoroughly
covered across two consecutive days. Further identical re-sweeps this cycle
would be diminishing-returns repeats rather than fresh signal.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633 (the most
recent comments on both, from earlier today, suggest a GitLab Runner is
actively being set up — worth re-checking again soon); (b) a new GitHub issue
of any size (ungroomed intake); (c) a new upstream CVE/release firing one of
the tracked ADR flip conditions; (d) an ArgoCD `v3.5.0` stable release
actually shipping, which would make the `latest`-tag override droppable.

This note is this cycle's honest record — the run already shipped 2 real PRs
before reaching it. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
