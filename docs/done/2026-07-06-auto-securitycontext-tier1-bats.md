# O2 measurement — per-scope PSS bats for 5 Tier-1 wave namespaces

(CHARTER **Objective O2**, due **2026-09-30**; O2 PSS coverage gap — five
namespaces (`argo-rollouts`, `velero`, `harbor`, `trivy-system`,
`node-exporter`) each have a `namespace.yaml` with all four PSA labels in
place, but their component bats files (`tests/argo-rollouts.bats`,
`tests/velero.bats`, `tests/harbor.bats`, `tests/trivy-operator.bats`,
`tests/node-exporter.bats`) only assert two of the four labels. O2's
measurement criterion requires `tests/securitycontext.bats` + per-scope
files to cover every namespace. Per `scripts/securitycontext-tests-check.sh`,
new per-scope tests must go in their own `tests/securitycontext-<scope>.bats`
file, not the frozen monolith. **No prerequisites — executor may pick up
immediately.** Create five new files following the
`tests/securitycontext-kargo.bats` / `tests/securitycontext-longhorn.bats`
pattern (namespace PSA labels: all 4 + safety checks + extras Application
exists):
`tests/securitycontext-argo-rollouts.bats` — PSA `restricted` (enforce:
restricted, enforce-version: latest, warn: restricted, audit: restricted) +
safety checks (NOT baseline, NOT privileged) + extras Application
`gitops/platform/argo-rollouts-extras.yaml` exists;
`tests/securitycontext-velero.bats` — PSA `restricted` (all 4 labels) +
safety checks (NOT baseline, NOT privileged) + extras Application
`gitops/platform/velero-extras.yaml` exists;
`tests/securitycontext-harbor.bats` — PSA `restricted` (all 4 labels) +
safety checks (NOT baseline, NOT privileged) + extras Application
`gitops/platform/harbor-extras.yaml` exists (harbor is on-demand but the
namespace PSA floor is always-on via the extras Application; test the
namespace manifest as committed);
`tests/securitycontext-trivy-system.bats` — PSA `baseline` (enforce:
baseline, enforce-version: latest, warn: baseline, audit: baseline) +
safety checks (NOT restricted, NOT privileged) + extras Application
`gitops/platform/trivy-extras.yaml` exists;
`tests/securitycontext-node-exporter.bats` — PSA `privileged` (enforce:
privileged, enforce-version: latest, warn: privileged, audit: privileged)
+ safety checks (NOT restricted, NOT baseline) + extras Application
`gitops/platform/node-exporter-extras.yaml` exists.
All 5 new files are additive — the partial checks in the component bats
files remain untouched. `make ci` must pass. `docs/done/` entry required.
(auto/securitycontext-tier1-bats)

## PR

https://github.com/tooming/k8s-lab/pull/335
