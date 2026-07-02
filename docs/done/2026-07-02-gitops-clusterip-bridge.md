# zz-dns-clusterip-bridge — bring out-of-band CNPs under GitOps

The `zz-dns-clusterip-bridge` CiliumNetworkPolicy (egress to `10.43.0.0/16`, the Service
ClusterIP CIDR — required for any default-deny pod to reach a ClusterIP service before
Cilium's socket-LB translates it to a backend pod IP) exists only as manually-applied
live-cluster state in 15+ namespaces; `gitops/harbor/networkpolicy/` is the sole
GitOps-managed copy (added as `allow-harbor-clusterip-egress.yaml` in the
`auto/harbor-application` PR — this file is the canonical reference shape). Without
it in GitOps, `make up` rebuilds silently break ClusterIP egress for every default-deny
namespace; any new namespace added via the NP fan-out pattern also inherits the gap.
Implementation (three sub-tasks):
(a) **Shared template** — add
`gitops/network/policies/zz-dns-clusterip-bridge.yaml` (a `CiliumNetworkPolicy`,
`endpointSelector: {}`, `egress: toCIDR: 10.43.0.0/16` — no port restriction, because
per-service pod-selector egress rules still gate which backends a pod may reach; this
only permits the ClusterIP frontend to be evaluated before Cilium's socket-LB
translates it). Copy the body verbatim from
`gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml`, updating the inline
comment to say "shared template" instead of harbor-specific; keep `metadata.name:
zz-dns-clusterip-bridge` (matches the live out-of-band name).
(b) **Per-overlay reference** — add the bridge template reference to every existing
per-namespace kustomization overlay (top-level namespaces use
`../../network/policies/zz-dns-clusterip-bridge.yaml`; `apps/*` namespaces use
`../../../network/policies/zz-dns-clusterip-bridge.yaml`). Affected overlays (24
total, listed by `gitops/*/networkpolicy/kustomization.yaml` and
`gitops/apps/*/networkpolicy/kustomization.yaml` at executor pickup — excludes harbor,
which already has `allow-harbor-clusterip-egress.yaml`; keep that harbor-specific file
but ALSO add the shared template reference so it is adopted consistently). For the
`gitops/argocd/networkpolicy/kustomization.yaml`, check if the existing
`allow-argocd-service-frontends.yaml` already covers `10.43.0.0/16` without port
restriction; if so, skip argocd to avoid a duplicate CNP; if it covers only specific
ports, add the bridge. For namespaces with no workloads today (`lab-gateway`, `network`
namespace overlay), still add the reference — the policy is a no-op when no pods exist
and prevents the gap recurring when pods are eventually added.
(c) **CI drift guard** — extend `tests/networkpolicy.bats` with a loop assertion: for
every `kustomization.yaml` under `gitops/` that references `default-deny.yaml`, assert
that the same `kustomization.yaml` also references `zz-dns-clusterip-bridge` (either
the shared template or an equivalent per-namespace file). This prevents a new namespace
being added via the NP fan-out pattern without the bridge — the same failure mode that
caused #315 originally. Update `docs/dependency-tree.md` with a one-line note that
`zz-dns-clusterip-bridge` is now a shared baseline template alongside `default-deny`
and `allow-dns-and-apiserver`. `docs/done/` entry required. `make ci` must pass.
**Executor note:** if the 24-file fan-out crosses ~400 lines per WAYS-OF-WORKING.md
§3, ship the shared template + always-on namespace overlays in PR 1 and the on-demand
namespace overlays (tidb, tidb-admin, inkless, longhorn, istio-system, artifactory,
harbor) in PR 2. The CI drift guard must land with PR 1. Closes #315.
(auto/gitops-clusterip-bridge)

## PR

#TBD
