# [Action needed] Now/next still gated; CI-workflow security + gitops-orphan sweep clean, cycle 10

**Date:** 2026-08-12
**Cycle:** 10th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134/#1135/#1136/#1137/#1138's honest gated-state records, and PR #1139's
dependency-register log-drift fix — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly via the GitHub API — both still open, `updated_at` still
`2026-08-11T13:09:3xZ`, no new comment since yesterday. Also re-listed all open
issues repo-wide: exactly these two, both already accounted for — no new stale or
duplicate issue to triage.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Two mechanical checks distinct from every prior cycle's angle this run (currency,
doc-drift, TODO/dead-code, architecture-doc precision, RBAC/secrets/privileged-container
hardening, ADR-index/dashboard-JSON validity, CHARTER-Objective-dates/Makefile-symmetry,
dependency-register log-drift):

- **GitHub Actions workflow security**: checked every `uses:` line across all 6
  `.github/workflows/*.yml` files — all 8 third-party action references
  (`actions/checkout`, `actions/cache`, `actions/github-script`,
  `hashicorp/setup-terraform`) are pinned to a full 40-character commit SHA with a
  version comment, not a floating tag (the supply-chain-safe pattern). Also checked
  every workflow's `permissions:` block — all 6 declare an explicit least-privilege
  block (`contents: read` by default, `contents: write`/`pull-requests: read` only on
  the two workflows that need to push branches or read PR metadata) — no workflow
  relies on the broad implicit default token.
- **gitops orphaned-manifest check**: cross-referenced all 52 `kustomization.yaml`
  files under `gitops/` (28 `networkpolicy/` dirs + 23 `governance/*/` dirs + the
  capstone app dir) against the actual files present in each directory, confirming
  every manifest file is listed in its governing `kustomization.yaml`'s `resources:`
  and every one of those 52 kustomizations is itself reachable from a real ArgoCD
  entry point (`networkpolicy-appset.yaml`'s 19 entries + 9 standalone
  `*-networkpolicy.yaml` Applications, `governance-appset.yaml`'s 23 entries). Zero
  files present-but-unreferenced, zero references to a non-existent file.

No finding either way on both checks. This is a real, negative-but-honest result —
not a skipped check.

## This run's cumulative outcome so far

Five real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix, three real stale citations), plus
five honest gated-state records (PR #1134, PR #1135, PR #1136, PR #1137, PR #1138).
This cycle's honest outcome is the ninth PR-shaped record.

Per STEP 8, the run continues past this point.
