# [Action needed] Now/next still gated; :latest-tag carve-out consistency sweep clean, cycle 21

**Date:** 2026-08-12
**Cycle:** 21st cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146/#1147/#1148/#1149/#1150's honest gated-state
records, PR #1139's dependency-register log-drift fix, and PRs #1142/#1144/#1145's
three self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Kyverno's `disallow-latest-tag` ClusterPolicy (`gitops/kyverno/policies/disallow-latest-tag.yaml`,
ADR-0019) rejects any `:latest` image tag except two explicitly documented,
namespace-scoped carve-outs (`capstone`, `inkless`) with their own flip conditions.
Grepped every manifest under `gitops/` for a literal `:latest` image tag and
cross-checked each hit against the policy's actual `exclude.any[].resources.namespaces`
list — a real class of bug would be a `:latest` tag in a namespace the policy
doesn't exclude (silently rejected at admission) or an exclusion the policy grants
that's no longer actually used (stale carve-out nobody needs anymore).

Found exactly 3 `:latest` hits, all inside the two excluded namespaces:
`gitops/inkless/inkless-statefulset.yaml` (`inkless` namespace — Aiven Inkless
publishes no stable named release, documented flip condition: a pinnable tag
ships) and `gitops/apps/capstone/{deployment,rollout}.yaml` (`capstone` namespace —
pending Kargo wiring a CI-pinned tag, issue #498). No `:latest` tag exists outside
either carve-out namespace, and both carve-outs are still actively used (not stale).

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus fifteen
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141,
#1143, #1146, #1147, #1148, #1149, #1150, and this one). This cycle's honest
outcome is the sixteenth such record.

Per STEP 8, the run continues past this point.
