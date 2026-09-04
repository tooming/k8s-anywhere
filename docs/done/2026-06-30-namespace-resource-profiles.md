# Namespace Resource Profiles — LimitRange defaults fan-out

**CHARTER Core Values §"Fits the 16 GB reality", RFC #294 — architect decision
2026-06-28; prerequisite `auto/platform-governance-appset` (RFC #293) merged in #303.**

Extend `gitops/platform/governance-appset.yaml` list with all namespace entries from
the RFC #294 mapping table. Add `gitops/governance/<namespace>/limitrange.yaml` for
every `standard`-tier namespace: `argocd`, `capstone`, `kyverno`, `external-secrets`,
`velero`, `argo-rollouts`, `trivy-system`, `moto`, `ack-system`, `kro`, `kargo`,
`lab-demo`, `data`, `storage`, `vault`, `lab-gateway`, `artifactory`, `kiali`. Add
`gitops/governance/observability/limitrange.yaml` with the `heavy` profile
(`default.cpu: "2000m"`, `default.memory: "2Gi"`; `defaultRequest.cpu: "100m"`,
`defaultRequest.memory: "128Mi"`; `max.cpu: "4000m"`, `max.memory: "8Gi"`). Excluded
namespaces (no LimitRange): `kube-system`, `kube-public`, `kube-node-lease`
(cluster-managed); `tidb`, `longhorn-system`, `istio-system`, `inkless` (on-demand
heavy — too variable for static defaults). Extend `tests/governance.bats`; update
`docs/dependency-tree.md`.

## What shipped

- **17 standard-tier leaf overlays** under `gitops/governance/<ns>/` (each a
  `kustomization.yaml` + `limitrange.yaml` named `standard-limits`, matching the
  `auto/platform-governance-appset` seed pattern): `argocd`, `capstone`, `kyverno`,
  `external-secrets`, `velero`, `argo-rollouts`, `trivy-system`, `moto`, `ack-system`,
  `kro`, `kargo`, `lab-demo`, `data`, `storage`, `vault`, `lab-gateway`, `kiali`
  (`argocd` + `capstone` already existed from the scaffold; the other 15 are new).
- **1 heavy-tier overlay** `gitops/governance/observability/` (`heavy-limits`).
- **`gitops/platform/governance-appset.yaml`** list-generator extended with one
  `<ns>-governance` element per namespace above (+ `observability-governance`).
- **`tests/governance.bats`** extended: full standard-tier list presence + Container
  type + `defaultRequest.cpu: 50m` + `default.memory: 512Mi`; the observability
  heavy-tier assertions (`2Gi` / `2000m` / `8Gi`); every namespace present in the
  appset; and a guard asserting the rejected registry namespace is NOT blessed.
- **`docs/dependency-tree.md`** wave-4 governance note updated to the full fan-out.

## ADR-0024 deviation from the RFC table — `artifactory` omitted

RFC #294's mapping table (authored 2026-06-28) lists `artifactory` as a standard-tier
namespace. **ADR-0024 — Harbor as the on-demand artifact registry (supersedes
ADR-0011)** was adopted around the same time and rejects Artifactory in favour of
Harbor (RFC #297, manifests pending). Per the binding ADR (and the
`scripts/adr-guard-hook.sh` mechanical guard, which blocks reintroducing the rejected
term in `gitops/`), this PR **omits the `artifactory` governance overlay**. Harbor's
namespace does not exist yet, so no `harbor` overlay is added either; a follow-up adds
`gitops/governance/harbor/` once the Harbor migration lands its namespace. The
omission is recorded inline in `governance-appset.yaml` and asserted by a bats test so
the gap cannot silently regress into re-blessing the legacy registry. This is the only
deviation from the RFC table; 17 of the 18 standard namespaces ship as specified.

## Note — `kiali` namespace

`kiali` is included per the binding RFC table. Kiali currently deploys into the
`istio-system` namespace (ADR-0012 ambient mesh, on-demand), so this `standard-limits`
LimitRange takes effect only if/when Kiali is given its own `kiali` namespace. It is
not an ADR-rejected technology, so it stays in the fan-out; flagged here for a future
reconciliation of the RFC table against the live Kiali topology.

## PR

https://github.com/tooming/k8s-anywhere/pull/304
