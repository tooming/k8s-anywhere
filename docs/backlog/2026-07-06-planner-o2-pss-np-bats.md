# Planner run 2026-07-06 — O2 PSS + NP per-scope bats coverage

## Trigger

All "Now / next" unchecked items are blocked or in-flight:
- `auto/cosign-enforce-flip` — blocked on maintainer `.sig` tag confirmation
- `auto/o4-ci-rejection-gate` — blocked on cosign-enforce-flip
- `auto/harbor-capstone-rewire` — blocked on maintainer Harbor footprint confirmation (#297)
- `auto/harbor-artifactory-decommission` — blocked on harbor-capstone-rewire
- `auto/tidb-dashboard` — in-flight (open PR #332)

Fallback chain: PLANNER role invoked per WAYS-OF-WORKING.md §6b.

## Gap analysis

### O2 PSS measurement — 5 missing per-scope securitycontext bats

All five namespaces have `namespace.yaml` files with all 4 PSA labels already in
place. Their component bats files only assert 2 of the 4 labels (enforce +
enforce-version, or enforce + audit, depending on the file). The O2 measurement
criterion requires `tests/securitycontext.bats` + per-scope files to cover every
namespace. Per `scripts/securitycontext-tests-check.sh`, per-scope additions go in
`tests/securitycontext-<scope>.bats`, not the frozen monolith.

| Namespace | PSA profile | Component bats | Labels tested | Missing |
|-----------|-------------|----------------|---------------|---------|
| `argo-rollouts` | restricted | `argo-rollouts.bats` | enforce + enforce-version | warn + audit |
| `velero` | restricted | `velero.bats` | enforce + audit | enforce-version + warn |
| `harbor` | restricted | `harbor.bats` | enforce + enforce-version | warn + audit |
| `trivy-system` | baseline | `trivy-operator.bats` | enforce + audit | enforce-version + warn |
| `node-exporter` | privileged | `node-exporter.bats` | enforce + enforce-version | warn + audit |

No workload-level securityContext assertions exist in any component bats for
these namespaces (Helm chart defaults satisfy the profile; the namespace PSA
enforce label is the runtime gate).

**Item groomed**: `auto/securitycontext-tier1-bats` — 5 new per-scope bats files.

### O2 NP measurement — 3 missing per-scope networkpolicy bats

Three namespaces have NP overlays wired into the appset or a dedicated NP
Application but no `tests/networkpolicy-<ns>.bats` file:

| Namespace | NP overlay | Appset entry | Per-scope bats |
|-----------|------------|--------------|----------------|
| `harbor` | `gitops/harbor/networkpolicy/` | networkpolicy-appset | missing |
| `kargo` | `gitops/kargo/networkpolicy/` | kargo-networkpolicy.yaml | missing |
| `node-exporter` | `gitops/node-exporter/networkpolicy/` | networkpolicy-appset | missing |

`tests/lib/networkpolicy-paths.bash` also lacks `HARBOR_NP`, `KARGO_NP`,
`NODE_EXPORTER_NP` entries.

**Item groomed**: `auto/networkpolicy-tier1-bats-wave2` — 3 new per-scope bats
files + 3 path vars in networkpolicy-paths.bash.

## Items added to ROADMAP "Now / next"

1. `auto/securitycontext-tier1-bats` — 🟢, no prerequisites
2. `auto/networkpolicy-tier1-bats-wave2` — 🟢, no prerequisites (pick up after #1 if available)

Both items are additive-only (no manifest changes, no ADR changes, no
architectural decisions). Both are well within the 400-line WIP cap.

## Blocking decisions not found

No new 🟡 architect items surfaced this run. The two remaining 🟡 O2 gaps
(PSS for `argocd` namespace and NP for `envoy-gateway-system` data-plane egress)
are already tracked in the Cross-cutting section and require architecture RFCs
before the executor can proceed.
