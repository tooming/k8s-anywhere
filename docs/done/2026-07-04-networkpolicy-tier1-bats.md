# NetworkPolicy bats fan-out — Tier-1 wave overlays

**NetworkPolicy bats fan-out — Tier-1 wave overlays** (CHARTER
**Objective O2**, due **2026-09-30**; O2 gap — four Tier-1 next-wave
namespaces have NetworkPolicy overlays but lack dedicated
`tests/networkpolicy-<ns>.bats` files; their NP assertions are
currently embedded in the component bats files
(`tests/kyverno.bats`, `tests/argo-rollouts.bats`,
`tests/velero.bats`, `tests/trivy-operator.bats`); O2's
measurement criterion says "tests/networkpolicy.bats +
per-scope files cover every namespace in gitops/" — the
per-scope files should exist for every namespace with an overlay,
mirroring the established pattern from all other namespace bats.
Wait for PR #324 (`auto/gitops-clusterip-bridge`) to merge first —
it adds the path variables `KYVERNO_NP`, `ARGO_ROLLOUTS_NP`,
`VELERO_NP`, `TRIVY_NP` to `tests/lib/networkpolicy-paths.bash`
that these new bats files will `load lib/networkpolicy-paths` to
use). Create four new files: `tests/networkpolicy-kyverno.bats`,
`tests/networkpolicy-argo-rollouts.bats`,
`tests/networkpolicy-velero.bats`,
`tests/networkpolicy-trivy-system.bats` — each structured as a
per-scope bats file (mirrors `tests/networkpolicy-kro.bats` as the
template; `load lib/networkpolicy-paths`; section header; assertions
for: overlay `kustomization.yaml` exists; references
`default-deny.yaml`; references `allow-dns-and-apiserver.yaml`;
references the `zz-dns-clusterip-bridge` template (post-PR-#324 the
shared template is the baseline); references each namespace's
specific allow files by name). For each file's specific allow
assertions, use the actual files present in the overlay at executor
pickup (e.g. for kyverno: `allow-kyverno-webhook-from-apiserver.yaml`
TCP 9443 from apiserver ipBlock, `allow-kyverno-metrics-from-observability.yaml`
TCP 8000; for argo-rollouts: the dashboard-from-gateway, metrics,
mimir-egress, plugin-egress allows; for velero: garage-egress,
metrics-ingress, kopia-egress allows; for trivy-system:
ghcr-egress, metrics-ingress allows). These tests are additive
— they do NOT remove the existing NP checks from the component
bats files; they exist for O2 measurement completeness.
`make ci` must pass. `docs/done/` entry required.
(auto/networkpolicy-tier1-bats)

## PR

#329 — https://github.com/tooming/k8s-lab/pull/329
