# Platform Governance appset — `gitops/governance/` structure + ApplicationSet

🟢 **Platform Governance appset — `gitops/governance/` structure +
ApplicationSet** (CHARTER **Core Values** §"Everything as code; GitOps deploys
it", RFC #293 — architect decision 2026-06-28). Add
`gitops/platform/governance-appset.yaml` (ApplicationSet with list-generator,
sync-wave annotation `"3"` on the ApplicationSet metadata; generated Applications
at sync-wave `"4"` via template annotation; auto-synced via template syncPolicy;
follows the existing `networkpolicy-appset.yaml` pattern). Each namespace that
needs governance objects gets a leaf directory `gitops/governance/<namespace>/`
containing `kustomization.yaml` + `limitrange.yaml`. Seed two entries to
demonstrate the pattern (`argocd` and `capstone` from the RFC #294 standard-tier
list). Each `kustomization.yaml` lists `resources: [limitrange.yaml]`; each
`limitrange.yaml` is a `standard`-tier LimitRange (`type: Container`;
`default.cpu: "500m"`, `default.memory: "512Mi"`; `defaultRequest.cpu: "50m"`,
`defaultRequest.memory: "64Mi"`; `max.cpu: "2000m"`, `max.memory: "4Gi"`).
Kyverno ClusterPolicies stay in `gitops/kyverno/policies/` — do NOT move them.
Update `docs/dependency-tree.md` with a governance layer note (parallel to the
networkpolicy-appset notes). New `tests/governance.bats`: governance-appset file
exists; is an ApplicationSet; has list-generator; has auto-sync template; the two
seed namespace dirs exist each with `kustomization.yaml` and `limitrange.yaml`.
`make ci` must pass. `docs/done/` entry required. Closes #293.
(auto/platform-governance-appset)

## PR

https://github.com/tooming/k8s-anywhere/pull/303
