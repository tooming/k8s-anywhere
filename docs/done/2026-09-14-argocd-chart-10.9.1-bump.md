# ArgoCD chart currency bump — 10.9.0 → 10.9.1 (appVersion v3.5.2 → v3.5.3)

## What

`argo-helm`'s `argo-cd` chart shipped `10.9.1` on 2026-09-14 (today),
bumping ArgoCD's own `appVersion` from `v3.5.2` to `v3.5.3`. This repo's
`chart_version` pin (module default in `infra/modules/argocd/variables.tf`,
mirrored into both `infra/live/local/argocd/terragrunt.hcl` and
`infra/live/oracle/argocd/terragrunt.hcl`) was still at `10.9.0`.

## Why

`docs/dependency-register.md`'s ArgoCD row is checked on a routine currency
cadence (see its own chained history — five prior dated entries this run
alone). This is the same pattern as every prior ArgoCD bump this run: catch
a new chart/appVersion release quickly rather than let the register go
stale.

## Verification

- `github.com/argoproj/argo-helm/releases.atom` — confirmed `argo-cd-10.9.1`
  published 2026-09-14, the newest tag on the chart's release list (checked
  the 5 most recent releases directly).
- `github.com/argoproj/argo-cd/releases/tag/v3.5.3` — read the release notes
  directly: 9 bug fixes (health-check corrections for KubeVirt/
  FlinkDeployment/Crossplane/GRPCRoute, repo-cache cleanup on revision
  change, operationState retry fix, SSO redirect-loop and hydrateTo fixes,
  AuthReconcile panic fix). **No CVE, no security fix, no breaking change**
  — the release notes explicitly carry no Security heading and no
  compatibility note beyond the standard "review upgrade docs" boilerplate.
- Fetched `raw.githubusercontent.com/argoproj/argo-helm/argo-cd-10.9.1/charts/argo-cd/values.yaml`
  directly: `global.networkPolicy.create` still defaults to `true` upstream
  at `10.9.1` — this repo's `infra/modules/argocd/values.yaml` override
  (`global.networkPolicy.create: false`, RFC #785) remains required and
  correct, unchanged by this bump.
- No GHSA re-sweep needed: the last full sweep (2026-09-03) confirmed every
  published advisory's affected range tops out at `3.4.2`; `v3.5.3` is
  further past that floor than the prior `v3.5.2` pin already was.

## Fix

- `infra/modules/argocd/variables.tf`: `chart_version` default `10.9.0` →
  `10.9.1`, description updated to name the new appVersion.
- `infra/live/local/argocd/terragrunt.hcl` and
  `infra/live/oracle/argocd/terragrunt.hcl`: `chart_version` input `10.9.0`
  → `10.9.1` (both backends move together, this repo's established
  discipline).
- `tests/argocd-chart-pin.bats`: both pin assertions and the stale-pin
  denylist updated to the new version.
- `docs/dependency-register.md`: new dated (2026-09-14) entry prepended
  to the ArgoCD row, chained via "Prior entry: ..." back through the full
  history, per this repo's established convention.

## ADR-0004 caveat

This remote, clusterless session verified the release's real existence and
its `values.yaml`/changelog facts directly, but cannot verify a fresh
`make up`/Terraform apply against either backend still bootstraps ArgoCD
cleanly on this new chart patch. Rollback is a one-line revert of the three
pin locations; ArgoCD's own GitOps-managed workloads are unaffected by an
ArgoCD-version bump alone (ADR-0001's bootstrap/workload seam).

## Verification (CI)

`make ci` — full clusterless suite (982 bats tests including the updated
`argocd-chart-pin.bats`, kustomize, kubeconform, terraform, ~40 drift-
detector scripts) — green except the expected `docs-done-pr-link-check`
placeholder failure, resolved by the standard follow-up commit backfilling
this PR's real link.

## PR

_placeholder — backfilled after PR creation_
