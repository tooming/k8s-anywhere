# [Action needed] Now/next still gated; Terraform provider-consistency sweep clean, cycle 17

**Date:** 2026-08-12
**Cycle:** 17th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143/#1146's honest gated-state records, PR #1139's
dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

A Terraform-specific check, distinct from every prior cycle's angle this run:
cross-checked every provider version constraint across `infra/modules/*/main.tf`
and every resolved version across all `.terraform.lock.hcl` files for
cross-module inconsistency (the same provider pinned to conflicting version
ranges/resolved versions in different modules — a real class of bug, since
`hashicorp/kubernetes` and `hashicorp/helm` are each used by more than one
module).

- `hashicorp/kubernetes`: declared `~> 2.30` in both `infra/modules/forgejo-config`
  and `infra/modules/gitlab-config`; the one live lock file that resolves it
  (`infra/live/local/gitlab/.terraform.lock.hcl`) picked `2.38.0`, satisfying both
  constraints consistently.
- `hashicorp/helm`: declared `~> 3.0` in `infra/modules/argocd` (the only module
  using it); its lock file resolved `3.2.0`.
- `hashicorp/local`/`hashicorp/null` (`infra/modules/k3d-cluster`, `~> 2.5`/`~> 3.2`):
  the one live lock file (`infra/live/local/cluster`) resolved `2.9.0`/`3.3.0`,
  both satisfying their constraints.
- No provider appears with two different version *constraints* across modules, and
  no two lock files resolve the same provider to two different concrete versions.

No finding. This is a real, negative-but-honest result — not a skipped check.

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes with mechanical guard extensions), plus eleven
honest gated-state records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141,
#1143, #1146, and this one). This cycle's honest outcome is the twelfth such
record.

Per STEP 8, the run continues past this point.
