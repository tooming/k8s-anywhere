# Fix stale securityContext key names in the argocd namespace comment

Doc-drift-author fallback (executor routine, STEP 6b — ROADMAP `Now / next`
fully gated again this cycle; no un-RFC'd 🟡 items, no open issues for the
triager, no fresh architect-lane finding in scope for architect/upgrade-drafter).
Found while extending Cycle 14's KRO/`containerSecurityContext` audit to
ArgoCD itself, the highest-blast-radius component in the cluster.

## What was found

`gitops/argocd/namespace.yaml`'s comment claimed
`infra/modules/argocd/values.yaml` carries a "global.podSecurityContext +
global.containerSecurityContext block." Reading the actual file showed this
was stale: PR #493 already fixed it to use `global.securityContext` for
pod-level settings plus each component's own chart-default
`containerSecurityContext`, with no global container-level key. The real
config has been correct since #493 — only this comment, elsewhere in the
repo, still described the pre-#493 (wrong) key names.

## What changed (comment-only, behavior-preserving)

Corrected the comment in `gitops/argocd/namespace.yaml` to describe the
actual, already-correct state and point at `infra/modules/argocd/values.yaml`'s
own comment for the full verification. No YAML keys, labels, or any
reconciled state changed.

## Validation

`make ci` — same 13 known pre-existing local bats failures as every prior
cycle this session (bats/yq toolchain mismatch in this sandbox; verified
identical failure list before and after this change). GitHub Actions is the
authoritative gate for this PR.

## PR

https://github.com/tooming/k8s-anywhere/pull/539
