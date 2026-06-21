# Planner run 2026-06-21 — gap analysis note

**Trigger:** Executor lane starved — both unchecked 🟢 items in Now/next require
maintainer in-cluster confirmation before they are buildable:
- `auto/argocd-pss-enforce` (ArgoCD PSS Phase 2) — needs maintainer to verify Phase 1
  is green in cluster before the securityContext hardening + enforce flip lands.
- `auto/cosign-enforce-flip` (verifyImages Audit→Enforce) — needs maintainer to confirm
  at least one cosign CI run pushed a `.sig` tag to Artifactory.

**Action:** Ran as fallback planner per STEP 6b chain. Three O2/O5 gaps found via
gap analysis and groomed into three new 🟢 Now/next items:

1. **NetworkPolicy fan-out — `external-secrets` namespace** (`auto/networkpolicy-external-secrets`)
   Gap: `external-secrets` got PSA labels in `auto/pss-external-secrets` but has no
   NetworkPolicy overlay. It is the last always-on namespace without an ADR-0016
   default-deny floor. The `networkpolicy-appset.yaml` generator covers all other
   always-on namespaces; `external-secrets` was simply not added when PSA landed.

2. **PSS-restricted + NetworkPolicy — `kro` namespace** (`auto/pss-kro-namespace`)
   Gap: The `kro` namespace (KRO controller, always-on auto-synced via `kro.yaml`)
   has neither PSA labels nor a NetworkPolicy overlay, and ADR-0017's per-namespace
   profile table has no `kro` row. Bundled because both items are small.

3. **Lab — s3manager dashboard** (`auto/s3manager-dashboard`)
   Gap: `s3manager` is in the always-on auto-synced set but has no Grafana dashboard
   — it is the only Application in `gitops/platform/` with `automated:` syncPolicy
   that lacks a `grafana/dashboards/lab-<name>.json`. (Cilium is excluded — it has no
   `automated:` block despite appearing in grepping results due to its comment text.)

**No open issues to groom** (GitHub issue list empty).
**No `docs/roadmap/incoming/` files to absorb** (directory contains only README.md).
