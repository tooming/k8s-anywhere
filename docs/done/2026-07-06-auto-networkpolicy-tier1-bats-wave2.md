# O2 measurement — per-scope NP bats for 3 late-addition namespaces

(CHARTER **Objective O2**, due **2026-09-30**; O2 NP coverage gap — three
namespaces (`harbor`, `kargo`, `node-exporter`) have NetworkPolicy overlays
in `gitops/*/networkpolicy/` and are wired into the appset or a dedicated NP
Application, but lack dedicated `tests/networkpolicy-<ns>.bats` files; the NP
drift guard only blocks per-namespace tests creeping back into the shared
baseline monolith — it does not require every overlay to have a per-scope
file. O2 says "per-scope files cover every namespace in gitops/". **No
prerequisites — executor may pick up immediately; pick up after
`auto/securitycontext-tier1-bats` if both are available.** Create three new
files following `tests/networkpolicy-kro.bats` as the template (`load
lib/networkpolicy-paths`; section header; assertions for: overlay
`kustomization.yaml` exists; references `default-deny.yaml`; references
`allow-dns-and-apiserver.yaml`; references `zz-dns-clusterip-bridge`; each
namespace's specific allow files by name). Also add three path vars to
`tests/lib/networkpolicy-paths.bash`:
`HARBOR_NP="$REPO/gitops/harbor/networkpolicy"`,
`KARGO_NP="$REPO/gitops/kargo/networkpolicy"`,
`NODE_EXPORTER_NP="$REPO/gitops/node-exporter/networkpolicy"`.
Per-namespace specific allows to assert (verify exact files at executor
pickup):
`harbor` — `allow-harbor-ingress.yaml`, `allow-harbor-garage-egress.yaml`,
`allow-harbor-valkey-egress.yaml`, `allow-harbor-intra-namespace.yaml`,
`allow-harbor-metrics-ingress.yaml` (all 5 files in overlay);
`kargo` — `allow-kargo-api-from-gateway.yaml`,
`allow-kargo-webhook-from-apiserver.yaml`, `allow-kargo-egress-argocd.yaml`,
`allow-kargo-egress-registry.yaml`, `allow-kargo-metrics-ingress.yaml`;
`node-exporter` — `allow-node-exporter-metrics-ingress.yaml`.
These tests are additive — they do NOT remove the existing NP checks from the
component bats files. `make ci` must pass. `docs/done/` entry required.
(auto/networkpolicy-tier1-bats-wave2)

## PR

#336
