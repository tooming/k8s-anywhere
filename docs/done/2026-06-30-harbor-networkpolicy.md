# Harbor NetworkPolicy floor + appset entry

**Harbor NetworkPolicy floor + appset entry** (CHARTER **Core
Values**, RFC #297 / ADR-0024 — architect decision 2026-06-30; **NP fan-out
pre-approved by ADR-0024 per WAYS-OF-WORKING.md §2**; **prerequisite:
`auto/harbor-application` merges first**). Mirror the artifactory NP overlay
(ADR-0016 §4 fan-out). Add `gitops/harbor/networkpolicy/kustomization.yaml`
(`namespace: harbor`) referencing the shared
`../../network/policies/default-deny.yaml` +
`../../network/policies/allow-dns-and-apiserver.yaml`, plus:
`allow-harbor-ingress.yaml` (ingress from `envoy-gateway-system` to the Harbor
core/portal/registry ports), `allow-harbor-garage-egress.yaml` (egress TCP
3900 to the `storage` Garage S3 backend), and an egress allow to the platform
**Valkey** in `data` (Harbor's external cache) — plus internal DB egress as
the chosen profile requires. Added a `harbor-networkpolicy` entry to
`gitops/platform/networkpolicy-appset.yaml` (auto-synced, wave 4 — mirror the
`artifactory-networkpolicy` entry: `appName: harbor-networkpolicy`,
`gitPath: gitops/harbor/networkpolicy`, `destNamespace: harbor`). The
`artifactory-networkpolicy` entry is not removed yet (decommission item).
Extended `tests/harbor.bats` with NP overlay assertions: kustomization exists;
default-deny + allow-dns-and-apiserver refs present; ingress-from-envoy on
port 80; egress-to-storage on port 3900; egress-to-data on port 6379
(Valkey); intra-namespace allow exists; appset entry present.

## PR

#307
