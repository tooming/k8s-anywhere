# [Action needed] Now/next still gated; image-tag/AppProject/duplicate-resource audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Three real merged PRs so far this run:
[#903](https://github.com/tooming/k8s-anywhere/pull/903) (kustomize orphan-file
guard — found and fixed a genuine dead-code bug, `allow-harbor-clusterip-egress.yaml`),
[#904](https://github.com/tooming/k8s-anywhere/pull/904) (this run's cycle-2
action-needed record), and
[#905](https://github.com/tooming/k8s-anywhere/pull/905) (added missing bats
coverage for `grafana/dashboards/tidb-demo.json`, which had zero test coverage
anywhere in the repo since PR #34).

## This cycle's fresh angles (all clean)

1. **`:latest` image-tag sweep, repo-wide.** Grepped every `gitops/`/`infra/`
   manifest for `image:.*:latest`. Found exactly two: `ghcr.io/aiven/inkless:latest`
   (explicitly recorded as the intentional pin in ADR-0015's own image table —
   Aiven doesn't publish semver tags for this experimental KIP-1150 broker) and
   `harbor.../library/hello:latest` in `gitops/apps/capstone/{rollout,deployment}.yaml`
   (the capstone CI/CD demo image, intentionally floating — GitLab CI rebuilds
   and pushes it continuously, and Kargo's Warehouse promotes by digest
   separately, per the on-disk config already cross-checked against issue
   #633's own investigation). Both are deliberate, documented design choices,
   not oversights.
2. **ArgoCD `project:` reference audit.** Every `Application` in the repo uses
   `project: default` (ArgoCD's always-present built-in project); zero custom
   `AppProject` resources exist, so there's nothing to cross-check for a
   dangling reference.
3. **Duplicate-resource-name audit via real `kustomize build`.** Installed the
   pinned `kustomize` v5.8.1 binary locally (absent from this sandbox by
   default) and built every one of the repo's 52 `kustomization.yaml`
   directories for real (this cycle's `make ci` run therefore exercised the
   actual `validate-kustomize.sh` gate instead of its locally-skipped path),
   then checked each build's output for duplicate `kind`/`namespace`/`name`
   triples. Zero found — expected, since `kustomize build` itself already
   rejects true intra-build duplicates, but this confirms the check for real
   rather than assuming it from the gate's mere green status.

`make ci` also ran with `bats`, `jq`, `mikefarah/yq` v4.53.3, and `kustomize`
v5.8.1 all installed locally this cycle (none present by default) — full green,
2340 assertions, 0 failures, with real kustomize builds and real yq parsing
exercised end-to-end rather than skipped.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record — three fresh angles tried, all clean,
following two real fixes earlier in this same run. The run continues to the
next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
