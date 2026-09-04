# Harbor governance LimitRange

**Harbor governance LimitRange** (CHARTER **Core Values** §"Fits the
16 GB reality" + §"Everything as code; GitOps deploys it"; RFC #294 /
RFC #297 — follow-up; **no prerequisites — executor may pick up
immediately**). The `gitops/platform/governance-appset.yaml` already
carries an explicit TODO comment: "A harbor governance overlay is added
once its namespace lands." The harbor namespace landed in
`auto/harbor-application` (checked off above). Close that gap now:
add `gitops/governance/harbor/kustomization.yaml` (listing
`resources: [../../base/limitrange-standard.yaml]`) using the **standard** tier
profile from RFC #294 (`type: Container`; `default.cpu: "500m"`,
`default.memory: "512Mi"`; `defaultRequest.cpu: "50m"`,
`defaultRequest.memory: "64Mi"`; `max.cpu: "2000m"`,
`max.memory: "4Gi"`) — same values as every other standard-tier
namespace (argocd, capstone, kyverno, etc.), via the shared base. Add the
`harbor-governance` entry to the list-generator in
`gitops/platform/governance-appset.yaml`:
`appName: harbor-governance`, `gitPath: gitops/governance/harbor`,
`destNamespace: harbor` (inserted after the `kiali-governance` entry,
before the `# heavy tier` comment, consistent with the existing
ordering). Extend `tests/governance.bats` with assertions:
`gitops/governance/harbor/kustomization.yaml` exists;
harbor references the shared base limitrange; the `harbor`
entry appears in `gitops/platform/governance-appset.yaml`.
Updated `docs/dependency-tree.md` with a one-line note that the
`harbor` namespace now has a LimitRange.

## PR

https://github.com/tooming/k8s-anywhere/pull/327
