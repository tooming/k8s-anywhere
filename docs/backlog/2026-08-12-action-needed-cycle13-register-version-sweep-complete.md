# [Action needed] Now/next still gated; dependency-register version cross-check now complete, cycle 13

**Date:** 2026-08-12
**Cycle:** 13th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141's honest gated-state records, PR #1139's dependency-register
log-drift fix, and PR #1142's Kargo cross-file version-drift fix + guard extension —
all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

A direct continuation of cycle 12's angle, not a repeat: cycle 12's sweep
cross-referenced `docs/dependency-register.md`'s claimed current chart/image
versions against the live gitops manifests and checked 15 of 32 rows before finding
and fixing the one real mismatch (Kargo, PR #1142). This cycle finished the sweep
against the remaining rows to close out the check properly rather than leaving it
half-done:

- **Garage** (`v2.3.0`), **Longhorn** (`1.11.3`), **cert-manager** (`1.21.1`) — all
  three cite a specific current version in the register; all three match their live
  manifest pin exactly (verified directly, plus a `git log` check on each manifest
  confirming no newer bump commit landed after the cited one).
- The remaining rows (Terraform/Terragrunt, RabbitMQ, Istio, Valkey, Envoy Gateway,
  Kyverno, Argo Rollouts, Velero, Oracle Cloud Infrastructure, k3s, GitLab,
  Mimir/Alloy/node-exporter) cite no specific version number to check against — not
  a gap, just not a version-drift-checkable row by construction.

**Result: all 32 rows in `docs/dependency-register.md` have now been examined by
this run's version cross-check** (18 version-checkable rows across cycles 12-13, all
now matching their live pins; 14 rows non-checkable by version). No further
mismatch found beyond the one already fixed in PR #1142.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), PR #1142 (Kargo cross-file
version-drift fix + `adr-chart-version-sync-check` guard extension), plus eight
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141, and
this one). This cycle's honest outcome is the ninth such record — but arrives with
a completed, no-longer-open cross-check as its concrete artifact.

Per STEP 8, the run continues past this point.
