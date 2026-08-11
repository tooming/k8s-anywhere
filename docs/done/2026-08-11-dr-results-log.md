# DR/capstone-demo results-history log — track pass/fail + elapsed time per run over time

(CHARTER **Goals** §"operational-resilience discipline" — DORA Pillar 3 concept,
testing-results tracking; planner-fallback gap analysis 2026-08-11, reached via
`executor.prompt.md` STEP 6b PLANNER role after all six standing Now/next items
were re-confirmed gated (the three GitLab→Forgejo migration items need live
verification; the `verifyImages` Enforce flip / O4 CI gate / capstone
`Deployment` removal are all gated on unconfirmed maintainer-confirmation
issues #631/#633, re-checked this run — both still open, no new confirmation
comment), the architect lane held no un-RFC'd 🟡 item, and this run's own
external chart-currency sweep and a janitor-style dead-code/duplication sweep
both came up clean. **No prerequisites — executor may pick up immediately.**)

Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s
Q13 ("Are test results tracked with remediation deadlines?") answered "Pass/fail
is enforced by exit codes... but there's no historical log of *past* run results
over time — only the current pass/fail, not a trend" and named the exact gap
this item closes: "a results log would let you see if the 10-minute RTO is
trending up as the lab grows, not just whether it passed today." Grepping
ROADMAP.md and `docs/` for "results log"/"RTO trend" found nothing already
tracking this.

Added `scripts/lib/dr-results-log.sh` (new shared lib, mirrors the existing
`budget-check.sh` extraction precedent — same header-comment convention
crediting why it's shared): one function
`dr_log_result <script_name> <status> <elapsed_s> <budget_s> <objective_tag>`
that appends one row to `docs/dr-results-log.md` — creating the file with a
header (`| Date (UTC) | Script | Status | Elapsed (s) | Budget (s) | Objective |`)
on first write if it doesn't exist yet. `status` is the literal string `PASS`
or `FAIL`; the date is `date -u +%Y-%m-%dT%H:%M:%SZ`. The log path is
overridable via `DR_RESULTS_LOG` (used by `tests/dr-results-log.bats` to log
to a scratch file, never the real one).

Wired the call into every DR/capstone script's pass AND fail exit path:
`scripts/dr-restore.sh` (Objective O3), `scripts/dr-bluegreen.sh`
(`NOMINAL_BUDGET_S` — this drill's pass/fail comes from continuous-availability
uptime%/outage-seconds thresholds, not a wall-clock deadline, so its Budget
column is log-only, deliberately not named `BUDGET_S` so it isn't mistaken for
an enforced one and doesn't trip `tests/budget-check-lib.bats`'s "every script
defining `BUDGET_S` sources `lib/budget-check.sh`" recurrence guard),
`scripts/dr-chaos.sh` (chaos), `scripts/capstone-demo.sh` (Objective O6) — so a
real invocation (this remote session cannot trigger one, ADR-0004) appends
exactly one row per run, pass or fail; never a fabricated one.

Updated `docs/DR.md` with a new "Results history log" section linking to
`docs/dr-results-log.md`; updated `docs/dora-audit-readiness.md` Q13's Answer/
Evidence/Gap to note the mechanism now exists (pending real data — an
empty/near-empty log is truthful, not a placeholder). Added
`tests/dr-results-log.bats` (clusterless, structural + functional): the lib
file exists and defines `dr_log_result`; each of the four scripts sources the
lib and calls `dr_log_result` on both its pass and fail paths (grep-based
assertions, mirroring `tests/hook-scripts-*.bats`'s style); a scratch-dir
integration test that sources the lib, calls it twice, and asserts the file
grows by exactly two well-formed rows under a single header (recurrence
guard: the header must not be re-written on subsequent appends); a check that
the real `docs/dr-results-log.md` ships with the header only and zero
fabricated rows.

## ADR-0004 caveat

This remote clusterless session cannot generate a real logged run (no
cluster), so `docs/dr-results-log.md` ships as an empty table (header only) —
real rows only accumulate once a maintainer or a live-cluster session
actually runs one of the four scripts.

## Rollback path

Revert `scripts/lib/dr-results-log.sh` and the four `source .../
dr-results-log.sh` + `dr_log_result` call sites; each script returns to its
prior pass/fail-only exit behavior. `docs/dr-results-log.md` can be deleted or
left in place (an unused, harmless file) either way.

## PR

(filled in after PR creation)
