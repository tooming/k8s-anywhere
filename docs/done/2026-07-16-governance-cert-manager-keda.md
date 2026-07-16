# Governance LimitRange fan-out — `cert-manager` + `keda`

**Governance LimitRange fan-out — `cert-manager` + `keda`** (CHARTER
**Core Values** §"Fits the 16 GB reality" + §"Everything as code; GitOps
deploys it"; RFC #294 / RFC #293 follow-up — **no prerequisites, executor may
pick up immediately**). `gitops/platform/governance-appset.yaml`'s
list-generator fans out a standard-tier LimitRange to every always-on
namespace, but `cert-manager` (ADR-0028) and `keda` (ADR-0029) both landed
after RFC #294's fan-out completed and were never added — each already has
its own namespace + default-deny NetworkPolicy overlay, just no governance
leaf (same gap `auto/harbor-governance-limitrange` closed for `harbor`).
Add `gitops/governance/cert-manager/kustomization.yaml` and
`gitops/governance/keda/kustomization.yaml` (each: `namespace: <ns>` +
`resources: [../base/limitrange-standard.yaml]`, mirroring
`gitops/governance/harbor/kustomization.yaml` exactly — no new
`limitrange.yaml`; both use the shared standard-tier base). Add
`cert-manager-governance` and `keda-governance` entries to the
list-generator in `gitops/platform/governance-appset.yaml` (insert after the
`node-exporter-governance` entry, before the `# heavy tier` comment, same
ordering convention as every existing entry). Extend `tests/governance.bats`:
add `cert-manager` and `keda` to the `STANDARD_NS` list (both checks that
iterate it — leaf-dir-exists and appset-lists-every-standard-namespace —
then cover both automatically), plus two dedicated test pairs mirroring the
existing harbor block (kustomization exists + references the shared base;
appset has the `<ns>-governance` entry, one pair per namespace). Update
`docs/dependency-tree.md`'s wave-3 governance note (the `governance` AppSet
parenthetical namespace list) to add `cert-manager` and `keda`. `make ci`
must pass. `docs/done/` entry required. (auto/governance-cert-manager-keda)

## PR

Autonomous scheduled executor run — see `auto/governance-cert-manager-keda`.
