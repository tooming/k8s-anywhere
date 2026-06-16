# argocd namespace — Phase 1 PSA warn+audit labels (RFC #205, ADR-0017)

**CHARTER Objective O2** (PSS-restricted fan-out, due 2026-09-30).

Phase 1 of the two-phase argocd namespace PSS rollout per RFC #205 and
ADR-0017 §"Staged rollout". Sets `warn: restricted` + `audit: restricted`
namespace labels to surface non-compliant pods in cluster events and audit
logs before Phase 2 adds `securityContext` fields to the ArgoCD Helm values
and flips `enforce: restricted`.

## Files delivered

| Path | Role |
|------|------|
| `gitops/argocd/namespace.yaml` | argocd Namespace manifest with Phase 1 PSA warn/audit labels at `restricted` |
| `gitops/platform/argocd-extras.yaml` | ArgoCD `Application` (sync-wave 0, SSA) that patches the Terraform-created argocd namespace with the labels |
| `tests/securitycontext.bats` | Six new bats assertions: namespace file exists, warn label, audit label, argocd-extras Application exists, targets correct path, uses ServerSideApply |

## Why Phase 1 only

The argocd namespace is created by Terraform bootstrap (`infra/modules/argocd`).
Flipping `enforce: restricted` without first adding `securityContext` overrides
to the ArgoCD Helm values (`global.podSecurityContext`,
`global.containerSecurityContext`) would break ArgoCD pod admission — those
Helm value changes are in `infra/modules/argocd/values.yaml` (an `infra/`
bootstrap change, classified 🟡 per WAYS-OF-WORKING.md §2) and require a
separate architect-reviewed PR. Phase 1 (this PR) establishes the auditing
floor; Phase 2 completes the enforcement flip once the Helm values are ready.

## PR

PR #217 — https://github.com/tooming/k8s-lab/pull/217
