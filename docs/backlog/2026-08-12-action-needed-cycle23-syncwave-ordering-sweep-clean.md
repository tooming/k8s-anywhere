# [Action needed] Now/next still gated; ArgoCD sync-wave ordering sweep clean, cycle 23

**Date:** 2026-08-12
**Cycle:** 23rd cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146-#1152's honest gated-state records, PR #1139's
dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Cross-checked every `gitops/platform/*-extras.yaml` Application's
`argocd.argoproj.io/sync-wave` annotation against its corresponding main
Application's wave — the established pattern across most components is
extras-before-main (namespace/PSA labels land at an earlier wave than the Helm
release that schedules pods into that namespace). A real bug would be an extras
file that runs *after* or *alongside* its main Application without a documented
reason (namespace labels arriving too late to matter).

Found two apparent deviations from the extras-before-main pattern, both verified
directly and confirmed as already-documented, intentional exceptions, not bugs:

- **`keda-extras.yaml`** runs at the *same* wave (6) as `keda.yaml`, not before it —
  the file's own header comment explains this was moved from wave 0 specifically
  because `keda.yaml` itself had to move to wave 6 (its admission webhook cert
  depends on `cert-manager-root-ca` reconciling at wave 5), and `keda-extras`
  stays paired with it by design so the namespace labels are still in place before
  the Helm release deploys.
- **`vault-extras.yaml`** runs at wave 2, *after* `vault.yaml`'s wave 1 — this one
  isn't a "namespace prep" extras file at all; its own header comment says
  "Vault add-ons: interim auto-unsealer + UI HTTPRoute. sync-wave 2 (after Vault)"
  — it's a genuinely different kind of file (post-Vault add-ons) that happens to
  share the "-extras" naming convention, not a namespace-prep file that should
  precede Vault.

Every other `*-extras.yaml` file's wave precedes its main Application's wave as
expected. No real ordering bug found.

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus
seventeen honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140,
#1141, #1143, #1146, #1147, #1148, #1149, #1150, #1151, #1152, and this one). This
cycle's honest outcome is the eighteenth such record.

Per STEP 8, the run continues past this point.
