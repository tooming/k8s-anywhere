# Bump Pyroscope chart `2.1.1` → `2.1.2`

Upgrade-drafter fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated this cycle: the same five `[ ]` items are blocked on the standing
maintainer-confirmation issues #631/#632/#633, all three still open with zero
comments; planner/architect/doc-drift/triager lenses came up empty; this
session hadn't yet tried the upgrade-drafter lens, so a fresh sweep of every
non-ADR-pinned Helm chart in `gitops/` was run this cycle).

## What changed

`gitops/platform/observability-pyroscope.yaml`'s `targetRevision` bumped
`2.1.1` → `2.1.2` (chart-only patch, released 2026-07-21; the chart's
`appVersion` stays `2.1.1` — confirmed via `Chart.yaml` fetched at the real
`pyroscope-2.1.2` git tag — so the Pyroscope binary itself is unchanged,
this is a pure chart-templating maintenance release). Same-source bump only
(still `https://grafana.github.io/helm-charts`, chart `pyroscope`), no
major-version jump, no ADR governs Pyroscope's version as a binding pin.

Verified the `podSecurityContext`/`securityContext` key paths this repo's
`valuesObject` depends on are unchanged in the new chart tag's
`templates/deployments-statefulsets.yaml` (both still reference
`$values.podSecurityContext` / `$values.securityContext` exactly as before)
— low risk of a silent schema drift. Updated the in-file comment citing the
verified chart tag from `pyroscope-2.1.1` to `pyroscope-2.1.2` to keep it
accurate.

## Why this version

Highest stable release, no major bump, no pinning ADR. Release notes/
changelog for `pyroscope-2.1.2` carried no CVE mention.

## Upstream notes

- Release: https://github.com/grafana/helm-charts/releases (tag `pyroscope-2.1.2`, published 2026-07-21)
- Chart.yaml at the tag: https://raw.githubusercontent.com/grafana/pyroscope/pyroscope-2.1.2/operations/pyroscope/helm/pyroscope/Chart.yaml
- Template verified: https://raw.githubusercontent.com/grafana/pyroscope/pyroscope-2.1.2/operations/pyroscope/helm/pyroscope/templates/deployments-statefulsets.yaml

## What `make ci` saw

Green (bats/kustomize/kubeconform/terraform/shellcheck/yamllint aren't
installed in this remote sandbox and gracefully skip; GitHub Actions is the
authoritative gate).

## PR

https://github.com/tooming/k8s-anywhere/pull/650
