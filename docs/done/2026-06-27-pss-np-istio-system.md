# PSS `privileged` labels + NetworkPolicy — `istio-system`

**CHARTER Objective O2**, due **2026-09-30**; O2 fan-out completion — ADR-0017
§"Per-namespace profile" already lists `istio-system → privileged` (istio-cni DaemonSet
mutates host CNI config; ztunnel requires `NET_ADMIN`; per ADR-0012) but no
`gitops/istio-system/namespace.yaml` exists. The istiod, istio-base, ztunnel, and
istio-cni Applications (all on-demand via `make istio-up`) deploy into this namespace.
Two changes bundled: (a) **PSA labels** — create `gitops/istio-system/namespace.yaml`
with all four PSA labels at `privileged` (`enforce: privileged`, `enforce-version:
latest`, `warn: privileged`, `audit: privileged`); add new auto-synced `Application`
`gitops/platform/istio-system-extras.yaml` (sync-wave 0, `ServerSideApply=true`,
`CreateNamespace=true` — harmless empty namespace before `make istio-up`; follows the
`kargo-extras` / `argocd-extras` naming convention). Confirm the ADR-0017
`istio-system → privileged` row cites ADR-0012 §"PSA profile" (add citation if
absent). (b) **NetworkPolicy** — add
`gitops/istio-system/networkpolicy/kustomization.yaml` referencing the two shared
baseline templates plus allow files: `allow-istio-intra-namespace.yaml`
(intra-namespace `podSelector: {}` — istiod control-plane internal traffic);
`allow-istio-metrics-ingress.yaml` (ingress TCP 15014 from `observability` — istiod
Prometheus scrape port); egress to kube-apiserver via baseline. Add
`istio-system-networkpolicy` entry to `networkpolicy-appset.yaml` (`gitPath:
gitops/istio-system/networkpolicy`, `destNamespace: istio-system`); sync policy
`automated: {prune: true, selfHeal: true}`. New `tests/securitycontext-istio.bats`:
`gitops/istio-system/namespace.yaml` exists; `enforce: privileged` present;
`enforce: restricted` absent. New `tests/networkpolicy-istio-system.bats` with istio-system
overlay assertions. Update `docs/dependency-tree.md` with istio-system PSS + NP note.
`make ci` passes. (auto/pss-np-istio-system)

## PR

#285
