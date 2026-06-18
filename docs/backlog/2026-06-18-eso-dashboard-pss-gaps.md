# Planner run 2026-06-18 — ESO dashboard (O5) + PSS gaps (O2)

**Run date:** 2026-06-18  
**Branch:** plan/2026-w25-eso-dashboard-pss-gaps  
**Executor lane state:** two blocked items; one new 🟢 item inserted; two 🟡 items surfaced.

---

## Why this run ran the planner role

The executor found two unchecked "Now / next" items, both blocked on explicit maintainer
cluster-verification prerequisites:

1. **ArgoCD PSS Phase 2** (`auto/argocd-pss-enforce`) — requires Phase 1 verified green
   in cluster before the enforce label is safe to apply. Maintainer must confirm PSS
   warn/audit mode hasn't surfaced violations in ArgoCD before the executor may build.

2. **verifyImages ClusterPolicy — Audit → Enforce flip** (`auto/cosign-enforce-flip`) —
   requires maintainer to confirm at least one CI run has successfully pushed a `.sig`
   OCI tag to Artifactory before the policy is flipped to `Enforce`. An image denied at
   admission without a corresponding signature blocks all deployments.

Neither can be built clusterlessly. The executor fell through to the planner fallback.

---

## Gap analysis findings

### O5 gap (due 2026-09-30): External Secrets has no dashboard

The `external-secrets` Application is auto-synced (`gitops/platform/external-secrets.yaml`)
and is therefore in scope for CHARTER Objective O5 ("every Application in the auto-synced
set has a real-metric Grafana dashboard"). No `lab-external-secrets.json` exists in
`grafana/dashboards/`, and no `prometheus.scrape "external_secrets"` block exists in
`gitops/platform/observability-alloy.yaml`.

ESO exposes Prometheus metrics at `:8080/metrics` via controller-runtime by default — the
same controller-runtime HTTP server used by kyverno, trivy-operator, and velero. Adding the
scrape and dashboard follows the identical pattern as those three components, making this
a clearly 🟢 executor item. Item added to "Now / next" **above** the two blocked items so
the executor lane remains active.

**New ROADMAP item:** `[ ] 🟢 External Secrets dashboard + Alloy scrape` → `(auto/external-secrets-dashboard)`

### O2 gaps (due 2026-09-30): two namespaces absent from ADR-0017

Both namespaces are absent from ADR-0017 §"Per-namespace profile" table and have no
PSA namespace labels:

**`external-secrets` namespace:**
- No `gitops/external-secrets/namespace.yaml`.
- ESO controller-manager and webhook pods use UID 65534 (controller-runtime default),
  are expected to be non-root. `restricted` is likely achievable but needs chart
  `valuesObject` audit before an `enforce` label is applied.
- Decision needed by architect: confirm PSA level + any chart patches.

**`envoy-gateway-system` namespace:**
- NetworkPolicy overlay landed in `auto/envoy-gateway-system-networkpolicy` ✓.
- PSA labels: none. Two pod types (controller + proxy) with different privilege needs.
- Proxy pods bind Service ports 80/443 (may need `NET_BIND_SERVICE`), and the
  controller mutates EnvoyProxy CRs. Profile could be `restricted`, `baseline`, or
  `privileged` depending on actual pod spec — cannot determine without cluster-side
  audit.
- Decision needed by architect: confirm PSA level for each pod type.

Both items added to Cross-cutting as 🟡 pending architect RFCs.

---

## Items added to ROADMAP.md

| Section | Item | Tier | Blocker |
|---------|------|------|---------|
| Now / next | External Secrets dashboard + Alloy scrape | 🟢 | None — buildable next executor run |
| Cross-cutting | PSS hardening — `external-secrets` namespace | 🟡 | Needs architect RFC |
| Cross-cutting | PSS hardening — `envoy-gateway-system` namespace | 🟡 | Needs architect RFC |

---

## What did NOT change

- The two existing blocked items remain as-is in the ROADMAP (unchecked, with their
  prerequisite notes intact). The planner does not check them off or change their text —
  that is the executor's job once the maintainer confirms the prerequisites.
- No issues were groomed (zero open issues in the repo at run time).
- No CHARTER.md changes — goals and objectives are unchanged.
