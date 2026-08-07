# GitHub Actions workflow job timeouts — close the gap + add a mechanical guard

Janitor sweep (executor.prompt.md STEP 6b fallback chain, 2026-08-07, third
cleanup this run): `ci.yml`'s own header comment documents a real incident (PR
#648, 2026-07-21) where the `unit`/`drift` jobs sat `in_progress` for 20+ minutes
with zero progress across three separate attempts, because without an explicit
`timeout-minutes:` GitHub Actions' 360-minute default job timeout applies — a
network-dependent step that hangs instead of failing blocks a run for hours with
no automatic recovery. `ci.yml` applied the fix to all six of its own jobs, but
the lesson was never propagated to the repo's five other workflow files.

**Verified directly (ADR-0004):** grepped every job block across all six
`.github/workflows/*.yml` files for `timeout-minutes:` — only `ci.yml`'s jobs had
it. Five jobs across five files had none: `auto-update-prs.yml`'s
`rebase-pr-branches` (fires on every push to main), `delete-closed-pr-branch.yml`'s
`delete-branch`, `pr-up-to-date.yml`'s `up-to-date`, `oracle-cluster-apply.yml`'s
`terragrunt` (real `terragrunt apply`/`plan` against live OCI infra), and —
worst instance — `oracle-cluster-apply-retry.yml`'s `retry`, which fires hourly
(`cron: "17 * * * *"`), so a single hang could otherwise strand a runner for up
to 6 hours before it matters.

**Fix:** added `timeout-minutes:` to all five jobs (5/10/20 minutes depending on
each job's real expected duration and whether it touches live cloud infra), each
with a comment pointing back to `ci.yml`'s incident precedent.

**Mechanical recurrence guard:** new `scripts/workflow-timeout-check.sh` parses
every job in every `.github/workflows/*.yml` file and flags any missing
`timeout-minutes:`. Wired into `make ci` + the GitHub Actions `drift` job (kept in
parity), a `PostToolUse` hook (`scripts/workflow-timeout-sync-hook.sh`, mirroring
the existing pattern), and bats coverage in two new scope files
(`tests/drift-workflow-timeout-check.bats`, `tests/hook-scripts-workflow-timeout.bats`
— both frozen-monolith parents get new scopes in their own files per the existing
convention).

`make ci` passes (2551 bats tests green, including this check's own coverage).

## PR

https://github.com/tooming/k8s-anywhere/pull/1067
