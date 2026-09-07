# Remove orphaned Argo Rollouts leftovers (post-#1497 cleanup)

## PR

[#1506](https://github.com/tooming/k8s-anywhere/pull/1506)

## What

PR #1497 (2026-09-06, the maintainer-directed "aggressive simplification")
removed Argo Rollouts entirely (ADR-0020, no replacement) and its own Status
paragraph claims "All `gitops/argo-rollouts/` ... manifests ... were
deleted." That sweep was thorough for the component's own manifests but
missed several files that referenced or covered Argo Rollouts indirectly —
this is a JANITOR-fallback cleanup (ROADMAP rule #9's coverage/hardening
sweep) that finds and removes them.

## Removed

- `gitops/argo-rollouts/dashboard-auth-externalsecret.yaml`,
  `gitops/argo-rollouts/dashboard-auth-middleware.yaml` — orphaned leftovers
  from PR #1482 (the Traefik basicAuth Middleware added for the Argo
  Rollouts dashboard CVE), never referenced by any `kustomization.yaml` and
  never cleaned up by #1497's removal sweep despite ADR-0020's claim.
- `scripts/rollouts-plugin-list-check.sh`,
  `scripts/rollouts-plugin-list-sync-hook.sh` — the drift check + PostToolUse
  hook for Argo Rollouts' plugin-list YAML shape. Confirmed zero references
  in `Makefile` or `.github/workflows/ci.yml` before deletion.
- `tests/fixtures/rollouts-plugin-list-check/` (both fixture trees).
- The `rollouts-plugin-list-sync-hook.sh` PostToolUse entry in
  `.claude/settings.json`.
- The 4-test `rollouts-plugin-list-sync-hook` block and the 3-test
  `rollouts-plugin-list-check` block from the frozen monoliths
  `tests/hook-scripts-coverage.bats` and `tests/drift-gitops-manifest-checks.bats`
  respectively (frozen snapshot refreshed via
  `make hook-scripts-coverage-tests-mark`).

## Bug found: a masked test

`tests/hook-scripts-coverage.bats`'s
`"rollouts-plugin-list-sync-hook: real argo-rollouts Application (plugin
values already YAML lists) exits 0"` test had been passing since #1497's
merge purely because `gitops/platform/argo-rollouts.yaml` no longer exists —
`scripts/rollouts-plugin-list-sync-hook.sh`'s `[ -f "$fp" ] || exit 0` guard
fired immediately, so the test was not actually exercising the "plugin
values are lists" logic its title claims (CLAUDE.md/executor.prompt.md's
"Gate integrity" — the #1 agent failure mode). Deleting the entire orphaned
subsystem removes the false-pass rather than trying to patch a test for
functionality that no longer exists.

## Also fixed: stale comments naming the removed script

Several shared-lib comments (`scripts/lib/yq-variant.sh`,
`scripts/yq-variant-guard-check.sh`, `tests/lib/yq.bash`,
`scripts/ok-bad-lib-check.sh`, `scripts/lib/colors.sh`) listed
`rollouts-plugin-list-check.sh` as one of several example callers/scripts
sharing a pattern — corrected to name only the real remaining callers
(`helm-chart-pin-check.sh`, `argocd-crd-ssa-check.sh`, `lab-health-check.sh`
as applicable), with a note on the removal where useful context.

`infra/modules/argocd/values.yaml`'s comment listing every Application that
sets a (schema-ignored) `source.kustomize.buildOptions` field per-Application
named `argo-rollouts-networkpolicy.yaml` plus several other now-removed
NetworkPolicy manifests (`kargo-networkpolicy.yaml`,
`kargo-project-networkpolicy.yaml`, `keda-networkpolicy.yaml`,
`kyverno-networkpolicy.yaml`, `velero-networkpolicy.yaml` — all removed
along with their respective components in #1497). Verified via
`grep -rl buildOptions gitops/` that only three manifests still set this
field (`cert-manager-networkpolicy.yaml`, `governance-appset.yaml`,
`networkpolicy-appset.yaml`) and corrected the list to match.

## Verification

- `make ci`: fully green, zero `not ok` lines.
- `grep -rl buildOptions gitops/` confirmed the corrected example list in
  `infra/modules/argocd/values.yaml` is now exhaustive and accurate.
- Confirmed no other live code/CI wiring referenced any of the deleted
  files before removing them.

## ADR compliance

No ADR was contradicted — this removes leftovers from an already-decided,
already-superseded component removal (ADR-0020, "Removed 2026-09-07").

## Behavior preserved

None of the deleted scripts/manifests were reachable from `make ci`,
`.github/workflows/ci.yml`, or any live ArgoCD Application before this
change (all orphaned) — deleting them changes no gate's pass/fail outcome
other than removing the false-pass masked test noted above.
