# ADR-0017 amendment — four Tier 1 next-wave namespace rows

- [x] **ADR-0017 amendment — four Tier 1 next-wave namespace rows** (CHARTER **Objective O2** record-keeping; docs-only) — Added all four Tier 1 next-wave rows to the ADR-0017 §"Per-namespace profile" table: `kyverno → baseline` (webhook TLS `fsGroup` carve-out per ADR-0019); `velero → baseline` (node-agent DaemonSet hostPath per ADR-0021); `argo-rollouts → restricted` (non-root-capable per ADR-0020); `trivy-system → baseline` (scan-job OCI unpack per ADR-0022). Added two bats assertions to `tests/securitycontext.bats` for the `kyverno` namespace (the only new namespace manifest merged on `main` at PR time); bats assertions for `velero`/`argo-rollouts`/`trivy-system` namespaces land automatically once PRs #179/#180/#183 merge and those manifest files are on `main` — no separate follow-up item needed. (auto/adr-0017-next-wave-rows)

## PR

PR #184 — https://github.com/tooming/k8s-lab/pull/184
