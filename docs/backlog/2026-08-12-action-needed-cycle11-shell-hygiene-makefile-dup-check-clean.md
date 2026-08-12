# [Action needed] Now/next still gated; shell-hygiene + Makefile-duplicate-target sweep clean, cycle 11

**Date:** 2026-08-12
**Cycle:** 11th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138's honest gated-state records, PR #1139's dependency-register fix, and
PR #1140's cycle-10 record — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

Two mechanical checks distinct from every prior cycle's angle this run (currency,
doc-drift, TODO/dead-code, architecture-doc precision, RBAC/secrets/privileged-container
hardening, ADR-index/dashboard-JSON validity, CHARTER-Objective-dates/Makefile-target-symmetry,
dependency-register log-drift, CI-workflow security/gitops-orphan check):

- **Shell script hygiene**: checked every one of the 108 `scripts/*.sh` files for a
  `set -` safety directive — zero files are missing one. The repo's own established
  (and consistent) convention: 92 "check"/"sync-hook" scripts use `set -uo pipefail`
  (deliberately omitting `-e` so they can run a grep/test past a first failure and
  report every finding, not just the first), and 16 action/bootstrap scripts use the
  stricter `set -euo pipefail` (fail fast on the first real error). No script silently
  runs with none of the three safety flags.
- **Makefile duplicate-target check**: grepped every top-level target definition in
  `Makefile` (excluding `.PHONY:` declaration lines) for a name defined twice — make's
  own behavior on a duplicate target is to silently prefer the last definition and
  warn only in `--warn` mode, which `make ci`/CI invocations don't pass, so a
  duplicate would be a real, silent footgun. Zero duplicates found.

No finding either way on both checks. This is a real, negative-but-honest result —
not a skipped check.

## This run's cumulative outcome so far

Five real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), plus six honest gated-state records
(PR #1134, #1135, #1136, #1137, #1138, #1140). This cycle's honest outcome is the
tenth PR-shaped record.

Per STEP 8, the run continues past this point.
