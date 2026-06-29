# NetworkPolicy extensions — Kiali allows in `istio-system`

**NetworkPolicy extensions — Kiali allows in `istio-system`** (CHARTER **Objective O2**,
due **2026-09-30**; RFC #288 — architect decision 2026-06-27;
dependency **already met**: `auto/pss-np-istio-system` (PR #285) is merged in main —
`gitops/istio-system/networkpolicy/` and the `istio-system-networkpolicy` appset entry
are confirmed present). Kiali co-resides in `istio-system` (no separate namespace per
RFC #288); its PSA profile is already covered by `istio-system → privileged` (PR #285).
This item adds two Kiali-specific per-pod NetworkPolicy allows to the existing overlay.
Add `gitops/istio-system/networkpolicy/allow-kiali-ingress.yaml` — ingress TCP 20001
from `namespaceSelector: kubernetes.io/metadata.name: envoy-gateway-system`; `podSelector:
app.kubernetes.io/name: kiali` (Envoy HTTPRoute `kiali.127.0.0.1.nip.io` per
`gitops/kiali/route.yaml`). Add
`gitops/istio-system/networkpolicy/allow-kiali-observability-egress.yaml` — egress TCP
9009 to `namespaceSelector: kubernetes.io/metadata.name: observability`; `podSelector:
app.kubernetes.io/name: kiali` (Kiali queries Mimir Prometheus at port 9009 per
`gitops/platform/kiali.yaml` `valuesObject.external_services.prometheus.url`). Update
`gitops/istio-system/networkpolicy/kustomization.yaml` to reference both new allow
files. Update ADR-0017 `istio-system → privileged` row to add parenthetical: "(Kiali
co-resides in this namespace; no separate `kiali` row needed.)". No new ArgoCD
Application or appset entry needed — the `istio-system-networkpolicy` appset entry from
PR #285 covers the full overlay directory (auto-synced via the appset template).
Extend `tests/networkpolicy-istio-system.bats`: `allow-kiali-ingress.yaml` exists and
targets TCP 20001 from `envoy-gateway-system`; `allow-kiali-observability-egress.yaml`
exists and targets TCP 9009 to `observability`; both are referenced in
`kustomization.yaml`. `make ci` must pass. `docs/done/` entry required.
(auto/kiali-np-istio-system)

## PR

https://github.com/tooming/k8s-lab/pull/299
