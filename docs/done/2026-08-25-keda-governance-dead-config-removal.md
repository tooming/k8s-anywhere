# chore: remove dead `keda-governance` entry (KEDA's on-demand conversion)

JANITOR-fallback cleanup, reached via `executor.prompt.md` STEP 6b — found
while auditing PR #1300's KEDA/KRO on-demand conversion for doc drift
(`auto/keda-kro-ondemand-doc-drift`, this same run's prior cycle): a real
manifest-level gap the doc-drift PR deliberately scoped out as "a distinct,
non-doc issue, better as its own bounded change."

## The gap

`gitops/platform/governance-appset.yaml`'s list-generator still carried a
`keda-governance` entry (`destNamespace: keda`, `CreateNamespace=true`,
`syncPolicy.automated` — same as every other entry in the list). KEDA's own
namespace-creating Application (`keda-extras`) converted to on-demand
alongside the engine in PR #1300 (ADR-0029's 2026-08-25 Re-evaluation log
entry), so this entry would have had ArgoCD recreate an otherwise-empty
`keda` namespace (just a LimitRange, no workload) on every reconciliation —
working against that conversion's own "fully on-demand, zero footprint"
intent. Low severity (a stray empty namespace, not a functional break) but
real, and this repo already has the exact precedent for the fix: a
`kiali-governance` entry was removed the same way (`istio-system` excluded
as an on-demand-heavy namespace too variable for static defaults) —
`tests/governance.bats`'s own comment block already documented that
precedent before this change.

## The fix

- Removed the `keda-governance` list entry from
  `gitops/platform/governance-appset.yaml`, with a comment explaining why
  (mirroring the kiali-governance removal precedent).
- Deleted the now-orphaned `gitops/governance/keda/` leaf directory (its
  `kustomization.yaml` had nothing left generating an Application for it —
  `scripts/appset-list-coverage-sync-hook.sh` caught this live as soon as the
  list entry was removed).
- `tests/governance.bats`: removed `keda` from `STANDARD_NS` and the three
  keda-specific feature tests; added two recurrence guards ("leaf directory
  does not exist" / "no keda-governance entry") mirroring this file's own
  established pattern for the kiali removal.
- `docs/decisions/adr-0029-keda-event-driven-autoscaling.md`: added a
  same-day "Follow-up" paragraph to the existing 2026-08-25 Re-evaluation log
  entry documenting this fix (the original entry didn't mention
  governance-appset at all).
- `docs/dependency-tree.md`: removed `keda` from the wave-4 governance
  namespace list, added a removal note next to the existing kiali-governance
  one.

`make ci`: green — full local run including real `bats` (installed this
session specifically to verify this test-file change; 2866+ tests, all
passing, including the two new guards) and the `appset-list-coverage-check`
hook that caught the orphaned directory live during development.
`kustomize`/`kubeconform`/`terraform` remain uninstalled locally (unaffected
by this diff — no Terraform/infra file touched); GitHub Actions CI runs
those.

## PR

https://github.com/tooming/k8s-anywhere/pull/1312
