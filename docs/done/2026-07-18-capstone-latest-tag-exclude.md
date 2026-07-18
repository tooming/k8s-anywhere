# `disallow-latest-tag` ClusterPolicy — exclude the `capstone` namespace

(RFC/issue #498 — architect decision 2026-07-18, implementing in the same PR as the
RFC issue, mirrors the inkless ADR-0017 audit pattern from issue #494 / PR #495.
**No prerequisites — executor may pick up immediately.**)
`gitops/kyverno/policies/disallow-latest-tag.yaml` is a hard, unconditional
`Enforce` rejection of any Pod whose image ends in `:latest` or carries no tag, with
no `exclude:` block. `gitops/apps/capstone/deployment.yaml` and `rollout.yaml` both
hardcode `image: artifactory.127.0.0.1.nip.io/docker-local/hello:latest` — on a
from-scratch `make up`, `capstone` syncs at wave 4, before `kyverno-policies` at
wave 5, so the initial Pod admits fine, but any *subsequent* Pod creation
(crash/restart, node evict, a Rollout scale event, or the exact "CI builds a new
image, roll the workload" flow capstone exists to demonstrate) is rejected — and
`capstone`'s `selfHeal: true` means ArgoCD keeps retrying and failing the same
reconcile. Added a narrow, explicitly-commented `exclude:` block to
`disallow-latest-tag.yaml` scoped to the `capstone` namespace only (mirrors the exact
`exclude: any: - resources: namespaces: [...]` shape
`require-pod-security-restricted.yaml` already uses), with a comment stating the
flip condition: remove the exclusion once
`gitops/apps/capstone/{deployment,rollout}.yaml` reference a real, CI-pinned tag
instead of the floating `:latest` placeholder (depends on wiring Kargo's promotion
pipeline to capstone's image ref — a separate, larger item this issue's flip
condition points at, not built here). Did not hardcode a guessed "real" tag
instead (ADR-0004 — this remote clusterless session cannot know what tags actually
exist in the live Artifactory registry). Updated ADR-0019's policy table row for
`disallow-latest-tag` (plus the "Scope & exceptions" carve-outs list) to document
the carve-out + flip condition (mirroring how the `verify-image-signatures`
Audit-mode carve-out is already documented there). Extended `tests/kyverno.bats`
with two assertions: exclude block present and scoped to the `capstone` namespace
only (not a blanket exclusion). `make ci` passes. Closes #498.

## PR

(filled in after PR creation)
