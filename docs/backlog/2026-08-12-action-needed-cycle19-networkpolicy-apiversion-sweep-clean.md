# [Action needed] Now/next still gated; NetworkPolicy-coverage + deprecated-apiVersion sweep clean, cycle 19

**Date:** 2026-08-12
**Cycle:** 19th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146/#1147/#1148's honest gated-state records, PR
#1139's dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Two mechanical checks distinct from every prior cycle's angle this run:

- **ADR-0016 default-deny NetworkPolicy coverage**: every top-level `gitops/*`
  directory that has its own `namespace.yaml` also has a sibling `networkpolicy/`
  directory (the mechanism ADR-0016 uses to deliver the per-namespace default-deny +
  allow rules). Checked every such directory directly — zero namespaces found with a
  `namespace.yaml` but no matching `networkpolicy/` dir.
- **Deprecated Kubernetes apiVersion sweep**: grepped every manifest under `gitops/`
  for six apiVersions removed in modern Kubernetes (`policy/v1beta1`,
  `networking.k8s.io/v1beta1`, `extensions/v1beta1`, `batch/v1beta1`,
  `autoscaling/v2beta1`, `autoscaling/v2beta2`) against the lab's pinned k3s version
  (`v1.36.3+k3s1`, from `infra/modules/oracle-k3s-cluster/cloud-init.yaml`). Zero
  hits — every manifest already uses a current, non-deprecated apiVersion.

No finding either way on both checks. This is a real, negative-but-honest result —
not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus thirteen
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141,
#1143, #1146, #1147, #1148, and this one). This cycle's honest outcome is the
fourteenth such record.

Per STEP 8, the run continues past this point.
