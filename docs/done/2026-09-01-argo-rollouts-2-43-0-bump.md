# Bump Argo Rollouts chart `2.41.1` → `2.43.0` (appVersion `v1.9.1` → `v1.10.0`)

(CHARTER **Core Values** §"Everything as code" + general dependency hygiene; upgrade-drafter fallback, executor.prompt.md STEP 6b — this run's seventh cycle, found via the digest written two cycles ago: [docs/industry/2026-W36-digest.md](../industry/2026-W36-digest.md) flagged the running Argo Rollouts appVersion as one minor release behind upstream's real newest and deliberately left it un-bumped in that digest's own PR to keep it singular. The "Now / next" lane remained fully gated and PLANNER found no ungroomed intake or un-RFC'd 🟡 item.)

Verified directly (not assumed, ADR-0004) against the real chart source (`raw.githubusercontent.com/argoproj/argo-helm/argo-rollouts-2.43.0/charts/argo-rollouts/Chart.yaml`): `version: 2.43.0`, `appVersion: v1.10.0`. `argoproj/argo-helm`'s tags also show an intermediate `argo-rollouts-2.42.0` release, skipped in favor of the highest stable release per this routine's own "pick the highest stable" convention. No pre-release, no major bump — chart stays on major `2`, app stays on major `1`.

Release notes (`github.com/argoproj/argo-rollouts/releases/tag/v1.10.0`) cite no security fixes and no breaking changes; real stability fixes: a panic-prevention guard for empty `Values` in the injected anti-affinity check, a deepcopy fix for ALB status updates (issues #3673/#4184), and flaky-test fixes.

**Schema compatibility verified (ADR-0004):** fetched the chart's real `values.yaml` at `2.43.0` — every path this Application sets (`controller.{replicas,resources,trafficRouterPlugins}`, `dashboard.{enabled,replicas,resources,containerSecurityContext}`) is present and unchanged. Notably, `dashboard.containerSecurityContext` still defaults to `{}` (empty) at this tag too, confirming the explicit override the 2026-08-19 finding added remains necessary, not something this bump could safely drop.

**This Application is ALWAYS-ON** (automated sync, unlike Kargo/TiDB's on-demand bumps earlier this same run) — this pin takes effect on the next ArgoCD reconciliation, not a manual bring-up.

Bumped `gitops/platform/argo-rollouts.yaml`'s `targetRevision: 2.41.1` → `2.43.0` and its header comment block. Updated [ADR-0020](../decisions/adr-0020-argo-rollouts-progressive-delivery.md)'s "Chart + version" note and appended a new dated entry to its Re-evaluation log. Updated `tests/argo-rollouts.bats`'s pin assertions (retitled, generalized the "pins a specific chart version" check away from a hardcoded `2.41.` regex, added a negative assertion for both superseded versions). Updated `docs/dependency-register.md`'s Argo Rollouts row.

**ADR-0004 caveat.** This remote clusterless session cannot verify the Argo Rollouts controller/dashboard pods actually restart cleanly on the new chart version on a live cluster, or that the capstone Rollout's canary steps continue to function correctly against the bumped controller. Since this is an always-on, auto-synced Application, that verification should happen promptly after this merges (watch `kubectl get pods -n argo-rollouts` and the "Lab — Argo Rollouts" dashboard). Rollback path: revert `targetRevision` back to `2.41.1`; ArgoCD's next sync would then roll the Deployments back to the prior chart's manifests.

## PR

https://github.com/tooming/k8s-anywhere/pull/1366
