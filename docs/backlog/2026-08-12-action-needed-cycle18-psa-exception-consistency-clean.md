# [Action needed] Now/next still gated; PSA-exception-table consistency sweep clean, cycle 18

**Date:** 2026-08-12
**Cycle:** 18th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146/#1147's honest gated-state records, PR #1139's
dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

ADR-0017 (PSS `restricted` across all namespaces) keeps an explicit "Carve-out
namespaces" exception table naming every namespace that deliberately runs at
`baseline`/`privileged` instead of `restricted`, each with its own justification and
flip condition. Checked whether the *live* PSA labels on every real namespace
manifest under `gitops/` actually match what that table says — a real class of
drift, since a manifest could silently diverge from its own governing table (the
same shape of bug as the three self-tracking-citation fixes earlier this run, just
against a table instead of a single prose sentence).

Found 10 real namespace manifests carrying a non-`restricted` PSA profile
(`gitops/tidb`, `gitops/inkless`, `gitops/trivy-system`, `gitops/istio-system`,
`gitops/longhorn`, `gitops/tidb-admin`, `gitops/envoy-gateway-system`,
`gitops/storage/garage`, `gitops/node-exporter`, `gitops/apps/demo`) and
cross-checked each one's actual enforce level against ADR-0017's exception table —
**every single one matches**: `storage`/`tidb`/`tidb-admin`/`vault` at `baseline`
(table says `baseline`), `envoy-gateway-system`/`trivy-system`/`inkless`/`lab-demo`
(→ `gitops/apps/demo`) at `baseline` (table says `baseline`), and
`longhorn-system`/`istio-system`/`node-exporter` at `privileged` (table says
`privileged`). No manifest has drifted from its documented exception.

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus twelve
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141,
#1143, #1146, #1147, and this one). This cycle's honest outcome is the thirteenth
such record.

Per STEP 8, the run continues past this point.
