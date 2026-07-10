# PSA `restricted` labels — `capstone-pipeline` namespace

🟢 **PSA `restricted` labels — `capstone-pipeline` namespace** (CHARTER
**Objective O2**, due **2026-09-30**; O2 hardening gap — the `capstone-pipeline`
namespace (created by Kargo's Project CRD per ADR-0023) has no `namespace.yaml`
in `gitops/kargo-project/` carrying PSA `restricted` labels; the O2 PSS coverage
loop added in `auto/o2-pss-coverage-loop` only flags namespaces whose
`namespace.yaml` already exists, so this gap is silent but real; no workloads
currently run in `capstone-pipeline` but the floor is defense-in-depth.
**No prerequisites — executor may pick up immediately.**) Add
`gitops/kargo-project/namespace.yaml` with four PSA `restricted` labels
(`pod-security.kubernetes.io/enforce: restricted`,
`pod-security.kubernetes.io/enforce-version: latest`,
`pod-security.kubernetes.io/warn: restricted`,
`pod-security.kubernetes.io/audit: restricted`; `metadata.name: capstone-pipeline`)
— mirrors the `gitops/apps/capstone/namespace.yaml` pattern. The kargo-project
ArgoCD Application sources the `gitops/kargo-project/` path in directory mode
(see `gitops/platform/kargo-project.yaml`); ArgoCD applies the new
`namespace.yaml` via SSA against the namespace the Kargo Project CRD already
created. Add a `capstone-pipeline → restricted` row to ADR-0017's
per-namespace profile table noting no workloads run there (defense-in-depth
floor; Kargo itself runs in the `kargo` namespace). Extend `tests/kargo.bats`
with two assertions: `gitops/kargo-project/namespace.yaml` exists; it carries
all four PSA `restricted` labels. `make ci` must pass. `docs/done/` entry
required. (auto/capstone-pipeline-psa)

## PR

#354
