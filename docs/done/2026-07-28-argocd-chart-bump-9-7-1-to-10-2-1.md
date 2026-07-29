# `argo-cd` Helm chart major bump — `9.7.1` → `10.2.1`

RFC #785 — architect decision 2026-07-28: **Approve**, with a required
`global.networkPolicy.create: false` companion override. **No prerequisites —
executor may pick up immediately.** Bump `infra/modules/argocd/variables.tf`'s
`chart_version` default `"9.7.1"` → `"10.2.1"` (`appVersion v3.4.4` → `v3.4.5`);
update the variable's description comment to match. Add
`global.networkPolicy.create: false` to `infra/modules/argocd/values.yaml` with
a comment citing RFC #785: this repo already hand-manages its own default-deny
+ allow-list `NetworkPolicy` set for the `argocd` namespace via GitOps
(`gitops/argocd/networkpolicy/`, ADR-0016 pattern), and chart `10.x` flips the
upstream default for this key from `false` to `true` — the override preserves
current behavior (RFC #785 verified this is the only functionally relevant key
in the `9.7.1`→`10.2.1` values-schema diff; everything else is irrelevant to
this repo's values or purely additive). Re-verify at pickup time that chart
`10.2.1` actually resolves from `https://argoproj.github.io/argo-helm` before
merging (RFC #785's authoring session could not reach that host directly —
confirm the live Helm-repo `index.yaml` entry exists, same due-diligence
pattern as the `auto/pyroscope-*`/`auto/grafana-chart-*` bumps). Extend the
relevant `tests/*.bats` chart-pin coverage to assert both the new
`chart_version` default and the `global.networkPolicy.create: false` override
are present (recurrence guard). `make ci` must pass. `docs/done/` entry
required. Closes #785.

## What was verified this run

`argoproj.github.io` is unreachable from this session's network policy (403 at
the proxy), same as RFC #785's authoring session found. Verified chart
`10.2.1`'s real availability a different way: fetched the same underlying
Helm-repo index the Pages site serves —
`https://raw.githubusercontent.com/argoproj/argo-helm/gh-pages/index.yaml`
(the `gh-pages` branch of the same repo, reachable via the raw CDN host) —
confirmed the `argo-cd` entry for `version: 10.2.1` exists, `appVersion:
v3.4.5`, `urls: [https://github.com/argoproj/argo-helm/releases/download/
argo-cd-10.2.1/argo-cd-10.2.1.tgz]`, `created: 2026-07-23T21:06:05Z`. Then
`curl -sIL` on that exact release-asset URL returned `HTTP 200` — the chart
package is real and downloadable, not just tagged. Same discipline as the
`auto/pyroscope-*`/`auto/grafana-chart-*` precedent this item's acceptance
criteria pointed at.

## What changed vs. what didn't

- `infra/modules/argocd/variables.tf` — `chart_version` default `9.7.1` →
  `10.2.1`; description comment updated to `10.2.1 => ArgoCD v3.4.5`.
- `infra/live/local/argocd/terragrunt.hcl` and
  `infra/live/oracle/argocd/terragrunt.hcl` — both explicitly pin
  `chart_version` (overriding the module default), so both needed the same
  bump or the module-level change would have been inert. Kept
  byte-identical per the existing `tests/oracle-cluster.bats` assertion.
- `infra/modules/argocd/values.yaml` — added `global.networkPolicy.create:
  false` under `global:`, with a comment citing RFC #785 and ADR-0016.
- New `tests/argocd-chart-pin.bats` — three assertions: the module's
  `chart_version` default is `10.2.1`; both `terragrunt.hcl` files carry the
  matching input (a recurrence guard for the exact "module default bumped but
  the live-env override left stale" bug class this item itself would have hit
  if only `variables.tf` were touched); `global.networkPolicy.create` reads
  `false` from `values.yaml`.
- The `global.image.tag: latest` override (pinned separately, tracking the
  upstream `/applicationsets` UI route commit #26666, not yet in any stable
  chart per issue #781's own investigation) is untouched — out of this item's
  scope, unaffected by the chart-packaging bump.
- No README/`docs/dependency-tree.md` update — neither references the ArgoCD
  chart version number, and this bump has no topology change.

## ADR-0004 caveat

This remote clusterless session cannot verify `terraform apply`/`helm upgrade`
actually reconciles cleanly against the new chart version on a live cluster —
no cluster reachable from this session. Rollback path: revert the four
`chart_version`/terragrunt-input/description edits plus the `values.yaml`
`networkPolicy` block; `terraform apply` re-converges on the prior chart
release, no data migration involved (declarative, idempotent).

## PR

[#788](https://github.com/tooming/k8s-anywhere/pull/788)
