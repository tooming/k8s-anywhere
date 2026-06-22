# Planner run 2026-06-22 — gap analysis note

**Trigger:** Executor lane starved — both unchecked 🟢 items in Now/next require
maintainer in-cluster confirmation before they are buildable:
- `auto/argocd-pss-enforce` (ArgoCD PSS Phase 2) — needs maintainer to verify Phase 1
  is green in cluster before the securityContext hardening + enforce flip lands.
- `auto/cosign-enforce-flip` (verifyImages Audit→Enforce) — needs maintainer to confirm
  at least one cosign CI run pushed a `.sig` tag to Artifactory.

**Action:** Ran as fallback planner per STEP 6b chain. One O2 gap found via gap
analysis and groomed into a new 🟢 Now/next item:

**`lab-demo` namespace PSA baseline + NetworkPolicy** (`auto/pss-np-lab-demo`)
- Gap: the `lab-demo` namespace hosts the always-on HotROD demo Application
  (`gitops/platform/demo.yaml`, `automated: {prune: true, selfHeal: true}`) but has
  no PSA labels and no default-deny NetworkPolicy floor. It is absent from the
  ADR-0017 §"Per-namespace profile" table. This was the only always-on namespace
  not covered by the existing PSS/NP fan-out.
- Fix: `gitops/apps/demo/namespace.yaml` (baseline PSA — HotROD runs as root);
  `gitops/apps/demo/networkpolicy/kustomization.yaml` (default-deny + allow-dns +
  egress TCP 4318 to observability for Tempo OTLP); `networkpolicy-appset.yaml`
  `lab-demo` entry; ADR-0017 row; bats tests; docs/dependency-tree.md update.

**Additional gap noted (not groomed — awaiting architect RFC):**
- `inkless` namespace (on-demand, `gitops/inkless/`) — no namespace.yaml, no PSA
  labels, no NetworkPolicy. The Inkless StatefulSet uses `ghcr.io/aiven/inkless:latest`
  with unknown UID/securityContext requirements; kafka-exporter sidecar also needs
  assessment. Filed as GitHub issue for the architect to research and RFC.

**No open issues to groom** (GitHub issue list empty at run time).
**No `docs/roadmap/incoming/` files to absorb** (directory contains only README.md).
