# [Action needed] Now/next still gated; security-hardening sweep clean, cycle 6

**Date:** 2026-08-12
**Cycle:** 6th cycle this run (after PR #1131, PRs #1132/#1133, PR #1134's cycle-4
record, and PR #1135's cycle-5 record — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

A dependency/security-hardening sweep, distinct from cycles 1–5's currency check,
doc-drift check, TODO/dead-code sweep, and architecture-doc precision check. Checked
directly against the live repo (ADR-0004):

- **RBAC over-permission**: grepped every `gitops/` manifest for
  `cluster-admin` bindings — zero hits. Zero hand-rolled `ClusterRoleBinding`
  manifests exist anywhere in the repo (every component's RBAC is chart-managed, not
  custom-authored), and a wildcard-verb/wildcard-resource grep against any
  repo-authored RBAC file found nothing.
- **Hardcoded secrets**: grepped every `gitops/` YAML for a literal `password:`
  value not routed through `secretKeyRef`/`valueFrom`/an `ExternalSecret` — zero
  hits. Every credential in the repo flows through Vault → External Secrets, per
  ADR pattern, with no exception found.
- **Privileged containers**: grepped for `privileged: true` anywhere under
  `gitops/` — zero hits (the one component that plausibly needs elevated
  host access, node-exporter, uses `hostPath` mounts with its own scoped
  `securityContext`, not a blanket `privileged: true`).

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Four real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
plus two honest gated-state records (PR #1134, PR #1135). This cycle's honest
outcome is the sixth.

Per STEP 8, the run continues past this point.
