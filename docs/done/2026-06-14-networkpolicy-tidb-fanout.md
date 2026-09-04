# NetworkPolicy fan-out — tidb + tidb-admin namespaces (PR auto/networkpolicy-tidb-fanout)

**ROADMAP item:** 🟢 NetworkPolicy fan-out — `tidb` + `tidb-admin` namespaces (CHARTER Objective O2, ADR-0016 §4)

Completed the ADR-0016 default-deny NetworkPolicy fan-out for the two on-demand TiDB
namespaces. Policies are auto-synced (cheap manifests, no pods) so the default-deny
floor is already in place before `make tidb-up` brings the TiDB cluster up.

## Files added

| File | Purpose |
|------|---------|
| `gitops/tidb/networkpolicy/kustomization.yaml` | Kustomize overlay pulling baseline templates + 4 per-workload allow rules |
| `gitops/tidb/networkpolicy/allow-tidb-intra-namespace.yaml` | Broad intra-namespace allow for all TiDB cluster flows (PD/TiKV/TiDB/tidb-demo) |
| `gitops/tidb/networkpolicy/allow-tidb-from-tidb-admin.yaml` | Ingress + egress to tidb-admin for TiDB Operator reconciliation |
| `gitops/tidb/networkpolicy/allow-tidb-kubelet-egress.yaml` | Egress TCP 10250 to nodes for TiKV topology probe (ipBlock 0.0.0.0/0) |
| `gitops/tidb/networkpolicy/allow-tidb-from-observability.yaml` | Ingress TCP 10080 from observability for Alloy scrape |
| `gitops/tidb-admin/networkpolicy/kustomization.yaml` | Kustomize overlay pulling baseline templates + egress-to-tidb allow |
| `gitops/tidb-admin/networkpolicy/allow-tidb-admin-egress-tidb.yaml` | Egress to tidb namespace for TiDB Operator reconciliation flows |
| `docs/done/2026-06-14-networkpolicy-tidb-fanout.md` | This file |

## Files modified

| File | Change |
|------|--------|
| `gitops/platform/networkpolicy-appset.yaml` | Added `tidb-networkpolicy` + `tidb-admin-networkpolicy` entries to the ApplicationSet list generator |
| `tests/networkpolicy.bats` | 22 new assertions covering both overlays: kustomization existence, namespace labels, baseline refs, per-allow-file existence and port/selector checks, AppSet entry checks |
| `docs/dependency-tree.md` | Added tidb + tidb-admin NetworkPolicy notes in Notes section; updated wave 4 table to list the two new generated Applications |
| `ROADMAP.md` | Item marked `[x]` |

## Design notes

**Intra-namespace pattern:** The TiDB cluster has many intra-namespace flows (PD ↔ TiKV
↔ TiDB ↔ tidb-demo) across ports 2379/2380/20160/20180/4000/10080. A broad
`allow-tidb-intra-namespace` (empty podSelector + ingress/egress from/to `podSelector: {}`)
matches the same pattern used for the observability namespace (all intentional couplings
of the same purpose-built stack).

**On-demand + auto-sync:** The ROADMAP spec notes these on-demand namespaces can
auto-sync their NetworkPolicy overlays (same pattern as `lab-gateway-networkpolicy`) so
the default-deny floor is present before `make tidb-up` runs — not racing pod start-up.

**Kubelet egress:** TiKV's topology-aware scheduling probes kubelet on TCP 10250. Node
IPs are not stable in the Docker-based lab so `ipBlock: cidr: 0.0.0.0/0` scoped to
port 10250 is used — the same pragmatic pattern as Alloy's kubelet/cAdvisor scrape in
the observability namespace.

## PR

https://github.com/tooming/k8s-anywhere/pull/203
