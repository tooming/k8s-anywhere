# [Action needed] Now/next still gated; resource-requests coverage sweep clean, cycle 20

**Date:** 2026-08-12
**Cycle:** 20th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146/#1147/#1148/#1149's honest gated-state records,
PR #1139's dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Checked every `Deployment`/`StatefulSet`/`DaemonSet` manifest under `gitops/` (both
plain manifests and ArgoCD `Application`s that set Helm `resources:` via
`valuesObject`) for a `resources:` block — an unbounded workload is a real
resource-exhaustion footgun on the lab's single-host 12 GB budget (ADR-0005). Zero
manifests found without one.

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus fourteen
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141,
#1143, #1146, #1147, #1148, #1149, and this one). This cycle's honest outcome is
the fifteenth such record.

Per STEP 8, the run continues past this point.
