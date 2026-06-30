# Planner run 2026-06-30 — Governance RFC grooming

## Context

The executor lane was empty this run: both unchecked 🟢 items in *Now / next*
have unmet prerequisites — `auto/cosign-enforce-flip` needs maintainer confirmation
that a `.sig` tag reached Artifactory (clusterless verification is not possible),
and `auto/o4-ci-rejection-gate` depends on that flip merging first.

The planner was invoked as the fallback role (STEP 6b, chain position 1).

## RFCs groomed this run

### RFC #293 — Platform Governance layer (groomed → closed)

RFC filed by the architect on 2026-06-28 with a complete `## Decision` and
`## Acceptance criteria` section. Decision: introduce `gitops/governance/<ns>/`
directory tree + `gitops/platform/governance-appset.yaml` (list-generator
ApplicationSet, sync-wave 3, auto-synced). Kyverno ClusterPolicies stay in
`gitops/kyverno/policies/`.

Groomed into one 🟢 Now/next item: **`auto/platform-governance-appset`**.

### RFC #294 — Namespace Resource Profiles (groomed → closed)

RFC filed by the architect on 2026-06-28 with a complete `## Decision` and
`## Acceptance criteria` section. Decision: LimitRange defaults per namespace
(two tiers: `standard` and `heavy`). No ResourceQuota in this iteration. Excluded:
`kube-system`, `kube-public`, `kube-node-lease`, `tidb`, `longhorn-system`,
`istio-system`, `inkless`.

Groomed into one 🟢 Now/next item: **`auto/namespace-resource-profiles`**
(prerequisite: `auto/platform-governance-appset` merges first).

## RFC NOT groomed — requires maintainer decision

### RFC #297 — Harbor as on-demand registry (supersedes ADR-0011)

This RFC explicitly contradicts binding ADR-0011. Per CLAUDE.md, no implementation
may proceed until the maintainer accepts the RFC. The issue body correctly flags this
as requiring owner approval. No ROADMAP changes made for this RFC; left open awaiting
maintainer decision.

## Net ROADMAP changes

- 2 new 🟢 items added to *Now / next* (`auto/platform-governance-appset`,
  `auto/namespace-resource-profiles`)
- 2 🟡 Cross-cutting entries updated to "Groomed ↗" stubs (RFC #293, #294)
- RFC issues #293 and #294 closed + labeled `groomed`
