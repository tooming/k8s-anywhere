# Drop ArgoCD's `global.image.tag: latest` override — resolved TODO

Janitor cleanup (`executor.prompt.md` STEP 6b, JANITOR fallback role — this
run's eighth cycle, Now/next starved by #631/#633 and the currency-bump lens
exhausted for this pass). Found via a stale-TODO sweep:
`infra/modules/argocd/values.yaml` carried a documented TODO since 2026-07-24
("drop this override once argo-cd chart >= the version that ships the
expose-appset-ui commit (#26666)... no stable v3.5.0 exists yet, re-verified
2026-07-24"). This same run's `auto/argocd-chart-10-2-3` PR (#993) bumped the
chart to `10.2.3` (appVersion `v3.5.0`) — the TODO's exact condition.

## What was verified

`git merge-base --is-ancestor 4d02fc2f5 v3.5.0` on a real `argoproj/argo-cd`
clone confirms `v3.5.0` is the first stable tag containing commit `4d02fc2f5`
("feat: expose Appset UI and fix pie chart summary (#26666)") — the exact
commit the TODO names. The chart's own `values.yaml` documents
`global.image.tag`'s default as `""`, "Overrides the global Argo CD image tag
whose default is the chart appVersion" — so removing this lab's override
resolves to the chart's own `v3.5.0` appVersion automatically, a real stable
tag, and stays in sync with the chart's own version on every future bump
instead of needing a manual re-pin.

## What changed

- `infra/modules/argocd/values.yaml`: removed `global.image.tag: latest` and
  its TODO comment; replaced with a comment explaining the resolution and
  pointing at the still-open gate below.
- `gitops/kyverno/policies/disallow-latest-tag.yaml`: **updated** (did NOT
  remove) the `argocd` namespace carve-out's comment block, recording that
  the code-level TODO is resolved but the exclusion itself is not yet safe to
  drop.
- `tests/kyverno.bats`: renamed the argocd-carve-out test to reflect the new,
  still-pending reason (rather than the now-stale "global.image.tag: latest
  pin" description) — the assertion itself is unchanged (the exclusion still
  exists).
- New standing `[Action required]` issue
  [#999](https://github.com/tooming/k8s-anywhere/issues/999), mirroring the
  #631/#633 pattern (ROADMAP.md rule #11).

## Why the Kyverno exclusion itself was NOT removed this run

`infra/modules/argocd` is Terraform-bootstrap-only (ADR-0001) — this
values.yaml change has **zero live-cluster effect** until the maintainer's
next `terraform apply` against the `argocd` unit. The `argocd` Kyverno
exclusion exists specifically because a prior incident (#632 investigation,
2026-07-24) showed that removing an equivalent protection while the live
cluster still ran `:latest`-tagged Pods caused every Pod recreation (crash,
restart, node evict) to be rejected by Kyverno — `application-controller`
OOMKilled and could never come back, and `helm upgrade` failed identically on
its pre-upgrade hook Job. Removing the exclusion now, before a live
`terraform apply` has actually replaced the running `:latest`-tagged Pods
with `v3.5.0`-tagged ones, would reintroduce that exact outage. This remote,
clusterless session cannot verify live cluster state (ADR-0004) — issue #999
is the standing, unclosed record of what needs confirming before the next
executor cycle can safely finish this cleanup (remove `argocd` from the
policy's `namespaces:` exclude list, delete the carve-out comment block, and
update the matching `tests/kyverno.bats` test).

## Rollback path

Revert `infra/modules/argocd/values.yaml`'s change (restores `global.image.tag:
latest`) — no live-cluster state depends on this pin beyond the next
`terraform apply`, same as any other Terraform-bootstrap-seam change in this
repo. No Kyverno policy behavior changed in this PR (the `argocd` exclusion
is unchanged), so there is nothing to roll back on that side.

## PR

https://github.com/tooming/k8s-anywhere/pull/1000
