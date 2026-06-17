# NetworkPolicy fan-out — `envoy-gateway-system` namespace

**PR:** auto/envoy-gateway-system-networkpolicy
**ROADMAP item:** `auto/envoy-gateway-system-networkpolicy`
**CHARTER objective:** O2 (all always-on namespaces have default-deny NetworkPolicy floor by 2026-09-30)
**ADR reference:** ADR-0016 §4 fan-out, RFC #206

## What was delivered

Closes the last always-on namespace without a NetworkPolicy default-deny floor
(`envoy-gateway-system` held the Envoy Gateway controller + proxy pods, which have
the highest blast-radius: every HTTPRoute traverses them).

### Files created

| Path | Role |
|------|------|
| `gitops/envoy-gateway-system/networkpolicy/kustomization.yaml` | Kustomize overlay: baselines + 4 allow files |
| `gitops/envoy-gateway-system/networkpolicy/allow-envoy-controller-metrics-ingress.yaml` | Ingress TCP 19001 from `observability` → controller pod |
| `gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-metrics-ingress.yaml` | Ingress TCP 19000 from `observability` → proxy pods |
| `gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-listener-ingress.yaml` | Ingress TCP 10080 from `0.0.0.0/0` → proxy pods (north-south listener) |
| `gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-backend-egress.yaml` | Egress from proxy pods to 12 backend namespaces (matchExpressions operator:In) |
| `gitops/platform/envoy-gateway-system-networkpolicy.yaml` | Auto-synced ArgoCD Application (wave 4, LoadRestrictionsNone) |

### Files updated

| Path | Change |
|------|--------|
| `tests/networkpolicy.bats` | 20 new tests: kustomization shape, 4 allow files, Application file |
| `docs/dependency-tree.md` | Wave-4 table row updated; new envoy-gateway-system NP bullet; old "separate item" note removed |
| `ROADMAP.md` | Item marked `[x]` |

## Design notes

- **Pod selectors within envoy-gateway-system:**
  - Controller: `app.kubernetes.io/name: envoy-gateway` (Envoy Gateway chart label)
  - Proxy: `app.kubernetes.io/component: proxy` (confirmed by existing codebase usage in
    `allow-argocd-server-from-gateway.yaml`, `allow-grafana-ingress-from-gateway.yaml`)
- **Listener port TCP 10080**: confirmed by RFC #206 ("Service port 80 → container 10080")
  and consistent with the `allow-grafana-ingress-from-gateway.yaml` comment pattern
- **Backend egress**: no port restriction — backend container ports vary by namespace;
  the matchExpressions operator:In approach matches the `velero-egress-kopia-pv` precedent
- All existing Alloy scrape egress rules (ports 19000/19001 to envoy-gateway-system) already
  existed in `gitops/observability/networkpolicy/allow-alloy-egress-external.yaml` —
  this PR adds the matching ingress rules on the envoy-gateway-system side
