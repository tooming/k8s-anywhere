# ADR-0017 `velero` PSA row correction + `docs/dependency-tree.md` stale notes

(CHARTER **Core Values** §"Docs & dashboards don't drift"; docs-only, two small
corrections bundled because both are tiny).

**(a) ADR-0017 velero row**: the per-namespace profile table said `velero → baseline`,
but the actual `gitops/velero/namespace.yaml` enforces `restricted` and
`tests/velero.bats` asserts `enforce: restricted`. The implementation uses a per-workload
annotation on the node-agent DaemonSet for the `hostPath` carve-out (matching the
node-exporter pattern in ADR-0017 §"Per-workload field carve-outs"), making the
`restricted` profile viable. Updated the ADR-0017 table row to reflect the actual
implementation: `velero | restricted | Controller runs non-root (UID 65534); node-agent
DaemonSet uses a per-workload annotation...`

**(b) `docs/dependency-tree.md` stale notes**: fixed two stale references:
1. Capstone Mermaid subgraph label — `"Capstone — build pipeline (steps 1–4 done; step 5
   pending)"` → `"Capstone — build pipeline (all 5 steps done)"` (step 5 shipped in
   `auto/capstone-step-5`, see `docs/done/auto-capstone-step-5.md`).
2. ArgoCD PSS Phase 1 note — removed the `"Phase 2 (separate ROADMAP item, pending
   infra/modules/argocd/values.yaml securityContext overrides)"` parenthetical and
   replaced with a combined Phase 1 + Phase 2 description reflecting Phase 2 shipping
   in `auto/argocd-pss-enforce` (see `docs/done/2026-06-24-argocd-pss-enforce.md`).

No code changes. All three fixes are docs-only.

## PR

#274
