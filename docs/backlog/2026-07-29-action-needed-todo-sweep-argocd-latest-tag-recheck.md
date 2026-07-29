# [Action needed] Now/next still gated; TODO sweep + ArgoCD `latest`-tag TODO re-verified live

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#832](https://github.com/tooming/k8s-anywhere/pull/832) (this run's
prior cycle: secret-scan + broad-egress NetworkPolicy audit, clean).

## This cycle's fresh angle

A repo-wide `TODO`/`FIXME`/`XXX:` sweep across `gitops/`, `infra/`,
`scripts/`, `*.md` (excluding `docs/backlog/`/`docs/done/` narrative files)
found exactly **one** live marker:
`infra/modules/argocd/values.yaml:15` — `global.image.tag: latest`, with the
comment "Pin to latest (master) to include the `/applicationsets` UI route
(merged post-v3.4.3, not yet in a stable release). TODO: drop this override
once argo-cd chart >= the version that ships the expose-appset-ui commit
(#26666)."

This is a real, live-verifiable claim, not just a stale comment — so rather
than leave it as an unactioned TODO or (wrongly) assume it's now resolvable
just because time has passed, this cycle checked it directly against
upstream (ADR-0004: verified, not assumed):

- The pinned chart is `10.2.1` (`infra/live/{local,oracle}/argocd/terragrunt.hcl`),
  whose `Chart.yaml` maps to `appVersion: v3.4.5` (confirmed directly via
  `raw.githubusercontent.com/argoproj/argo-helm/main/charts/argo-cd/Chart.yaml`)
  — already past the `v3.4.3` cutoff the TODO names.
- Fetched PR #26666's head commit via `git ls-remote
  https://github.com/argoproj/argo-cd refs/pull/26666/head` (`75c44d3`).
- Directly diffed `ui/src/app/app.tsx` at tag `v3.4.5` vs. `v3.4.3` vs.
  `master`: **`v3.4.5` still ships the `/applicationsets` route commented
  out** (`// '/applicationsets': {component: applications.component},`,
  with upstream's own "TODO: Uncomment when ApplicationSet details page is
  fully implemented" note) — identical to `v3.4.3`. Only `master`/HEAD has
  the route actually uncommented and wired into the sidebar nav.

**Conclusion: the TODO's condition is still not met** — no stable
`argo-cd` release (through `v3.4.5`, the current chart's `appVersion`) ships
the feature yet, so the `global.image.tag: latest` override in
`infra/modules/argocd/values.yaml` is still necessary and correctly
documented; nothing to change. This avoids a wrong "fix" that would have
silently broken the applicationsets UI route this override exists for.

No bounded, real, behavior-preserving cleanup or upgrade qualified this
cycle. `make ci` is unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake); (d) a future `argo-cd` stable release
≥ the one that ships the uncommented `/applicationsets` route, at which
point the `global.image.tag: latest` override in
`infra/modules/argocd/values.yaml` becomes droppable (revert to the chart's
own default pinned image tag) — worth a fast recheck on the next
upgrade-drafter pass that touches the `argo-cd` chart version.

This note is this cycle's honest record — a genuinely distinct check (a
live TODO verified against real upstream source, not a repeat of a prior
cycle's technique). The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
