# Bump ArgoCD Helm chart `9.5.20` → `9.7.1` (appVersion `v3.4.3` → `v3.4.4`)

CHARTER **Core Values** §"Everything as code" + general dependency hygiene.
Upgrade-drafter fallback sweep (`executor.prompt.md` STEP 6b) after the
"Now / next" lane again came up fully gated on standing maintainer-confirmation
issues #631/#632/#633 (re-checked this cycle — still no confirmation comments
on any of the three), and the planner fallback found no ROADMAP gap (no open
issues to groom, `docs/roadmap/incoming/` empty, `make ci`'s drift signals
— readme-check, lab-ui-check, ADR chart-version/image-pin sync, stale
"Follow-up:" sweep, routines sync — all clean).

- Component: `argo-cd` Helm chart, `argoproj.github.io/argo-helm` repo
  (Terraform-bootstrap seam, ADR-0001 — `infra/modules/argocd/`, not
  gitops-managed). No ADR pins ArgoCD's chart/app version specifically.
- From → To: chart `9.5.20` (appVersion `v3.4.3`) → chart `9.7.1` (appVersion
  `v3.4.4`).
- Why this version: verified directly against the real chart index
  (`https://raw.githubusercontent.com/argoproj/argo-helm/gh-pages/index.yaml`,
  fetched live — `api.github.com`/`github.com` are proxy-blocked in this
  environment but this raw CDN host is not, same pattern noted in prior
  ADR-0004 verifications in this repo) — `9.7.1` (created 2026-06-26) is the
  newest chart release still on the pinned major line `9.x`; `10.1.x`/`10.2.0`
  exist but are a major bump (`9.x` → `10.x`), which upgrade-drafter's own
  scope rules explicitly leave for an architect RFC, not this routine. No
  pre-release versions were considered. The prior upgrade-drafter sweep
  earlier today (`docs/done/2026-07-23-tidb-version-bump-8-1-2-to-8-5-7.md`)
  listed ArgoCD as "already current," which this fresh direct-index check
  shows was inaccurate — `9.7.1` was already the newest `9.x` release at that
  time too; this PR corrects it with a properly verified pin.
- **What changed vs. what didn't:** this bumps the Helm *chart* (templates/
  schema) version only. The actual ArgoCD *image* deployed stays pinned to
  `global.image.tag: latest` in `infra/modules/argocd/values.yaml` — a
  pre-existing, separately-tracked override (documented inline: "Pin to
  latest (master) to include the /applicationsets UI route... TODO: drop
  this override once argo-cd chart >= the version that ships the
  expose-appset-ui commit") — untouched here, out of this routine's scope.
- **ADR-0004 caveat:** this remote clusterless session cannot verify
  `helm_release`/`terraform apply` actually reconciles cleanly against the
  new chart version on a live cluster (no cluster reachable from this
  session). Rollback path: revert the three `chart_version`/description
  edits below; ArgoCD's Terraform module is idempotent, so a re-apply with
  the old pin restores the prior chart release with no data loss (ArgoCD's
  own state — Applications, repo credentials — lives in the `argocd`
  namespace's Secrets/ConfigMaps, not in the chart version).

## Files changed

- `infra/modules/argocd/variables.tf` — `chart_version` default `9.5.20` → `9.7.1`, description updated.
- `infra/live/local/argocd/terragrunt.hcl` — `chart_version = "9.7.1"`.
- `infra/live/oracle/argocd/terragrunt.hcl` — `chart_version = "9.7.1"`.
- `infra/modules/argocd/values.yaml` — updated the one comment citing the pinned
  chart version for its own PSS-verification note (`argo-cd-9.5.20` →
  `argo-cd-9.7.1`); the two `docs/done/2026-07-18-fix-argocd-podsecuritycontext-key.md`
  citations of `9.5.20` are left untouched — they are a historical record of what
  was verified on that date, not a live claim about the current pin.

No topology change, so no README/`docs/dependency-tree.md` update — neither
references the ArgoCD chart version number. `make ci` (terraform fmt/validate
included, runs in GitHub Actions per CLAUDE.md — no `terraform` binary
available in this remote clusterless session to run it locally) must pass.

## PR

(filled in after PR creation)
