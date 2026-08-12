# [Action needed] Now/next still gated; script-reference integrity sweep clean, cycle 16

**Date:** 2026-08-12
**Cycle:** 16th cycle this run (after PR #1131, PRs #1132/#1133, PRs
#1134-#1138/#1140/#1141/#1143's honest gated-state records, PR #1139's
dependency-register log-drift fix, and PRs #1142/#1144/#1145's three
self-tracking-citation drift fixes + guard extensions — all merged).

## What's blocked

Unchanged: the same six Now/next items remain gated (three sequential
Forgejo-migration items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed
issue #631; capstone Deployment removal on unconfirmed issue #633). Re-checked both
issues directly — still open, no new comment since 2026-08-11.

## This cycle's fresh angle (per STEP 8's "widen the lens" guidance)

After three consecutive cycles (12, 14, 15) found real version-citation drift by
auditing narrow-coverage guard scripts, this cycle checked a different mechanical
integrity question: does every `scripts/*.sh` path *referenced* from an invocation
site actually exist on disk? A referenced-but-missing script is a silent footgun —
`bash scripts/typo'd-name.sh` fails loudly at call time, but nothing catches the
typo until that exact code path runs.

Checked every `scripts/*.sh` reference in:
- `Makefile` (every target's script invocation) — 0 missing.
- `.github/workflows/*.yml` (all 6 workflow files) — 0 missing.
- `.githooks/*` (the installed pre-push hook) — 0 missing.
- `.claude/settings.json` (the PostToolUse/SessionStart hook wiring) — 0 missing.

Also re-ran `scripts/hook-scripts-coverage-tests-check.sh` directly (the guard that
keeps `tests/hook-scripts-coverage.bats` from silently missing a new hook script's
test scope) — clean, no gap.

No finding. This is a real, negative-but-honest result — not a skipped check.
(`scripts/helm-chart-pin-check.sh`, the other candidate for this cycle's angle,
requires the real `mikefarah/yq` binary and `helm` to resolve chart versions
against live repos — unavailable in this clusterless sandbox per the established
14-failure local baseline; it already runs in GitHub Actions CI on every push, so
any real chart-pin regression would already have blocked the PR that introduced it.)

## This run's cumulative outcome so far

Six real deliverables landed this run: PR #1131 (Loki/Tempo/Pyroscope dashboards,
CHARTER O5), PRs #1132/#1133 (stateless-surface criticality tiering, DORA audit Q2),
PR #1139 (dependency-register.md log-drift fix), and PRs #1142/#1144/#1145 (three
self-tracking-citation drift fixes — Kargo/ADR-0023, Valkey/ADR-0018, ACK/context.md
— each with a matching mechanical guard extension), plus ten honest gated-state
records (PR #1134, #1135, #1136, #1137, #1138, #1140, #1141, #1143, and this one).
This cycle's honest outcome is the eleventh such record.

Per STEP 8, the run continues past this point.
