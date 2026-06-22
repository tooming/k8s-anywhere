# PSA baseline + NetworkPolicy — `lab-demo` namespace

**PR:** auto/pss-np-lab-demo  
**Date:** 2026-06-22  
**ROADMAP item:** 🟢 PSA baseline + NetworkPolicy — `lab-demo` namespace (CHARTER Objective O2, due 2026-09-30)

## What was delivered

- `gitops/apps/demo/namespace.yaml` — explicit `lab-demo` namespace manifest with all
  four PSA labels at `baseline` (`enforce`, `enforce-version`, `warn`, `audit`). `baseline`
  (not `restricted`) because `jaegertracing/example-hotrod` runs as root; see ADR-0017
  §Per-namespace profile for the flip condition.
- `gitops/apps/demo/networkpolicy/kustomization.yaml` — default-deny-all +
  allow-dns-and-apiserver baseline + `allow-demo-egress-tempo.yaml`.
- `gitops/apps/demo/networkpolicy/allow-demo-egress-tempo.yaml` — egress TCP 4318 from
  `app: hello` pods to Tempo in the `observability` namespace (OTLP HTTP trace export;
  the matching ingress allow already existed in `allow-tempo-ingress-otlp.yaml`).
- `gitops/platform/networkpolicy-appset.yaml` — `lab-demo-networkpolicy` entry added to
  the list generator (auto-synced, wave 4, `lab-demo` namespace).
- `docs/decisions/adr-0017-pod-security-standards-restricted.md` — `lab-demo → baseline`
  row added to the §Per-namespace profile table with flip condition.
- `tests/lib/networkpolicy-paths.bash` — `LAB_DEMO_NP` path variable added.
- `tests/networkpolicy-lab-demo.bats` — 9 clusterless structural assertions.
- `tests/securitycontext-lab-demo.bats` — 6 clusterless PSA label assertions.
- `docs/dependency-tree.md` — `lab-demo` PSA + NP entry added.
