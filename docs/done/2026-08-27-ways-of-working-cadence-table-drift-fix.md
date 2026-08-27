# Fix `docs/WAYS-OF-WORKING.md`'s stale Executor cadence table row, add a self-checking guard

Bugfix, not a ROADMAP item: reached via `executor.prompt.md` STEP 6b/ROADMAP rule #9
after the "Now / next" lane was re-confirmed fully gated this cycle — both standing
GitLab→Forgejo migration items are still blocked on the same live-cluster-design
prerequisite (`make up`'s bootstrap sequence still calls the GitLab targets directly;
Forgejo's push auth model is SSH-keyed, not HTTPS+PAT, so a same-shaped rename would be
unverified per ADR-0004), and the capstone-`Deployment`-removal item is still gated on
issue #633 (re-checked this cycle: latest comment 2026-08-25 09:34 UTC still reports the
Envoy Gateway control-plane bug blocking a real Kargo promotion, unresolved). Every open
GitHub issue is a standing `[Action required]` maintainer-confirmation gate (#633, #1229,
#1345) — none is ungroomed intake or an `rfc` issue, so planner-style grooming had nothing
new either.

Fresh angle this cycle (per rule #9's "try a lens the last pass didn't"): audited
`docs/WAYS-OF-WORKING.md` §1's routine registry table — the doc that says of itself
"this table mirrors [`routines/routines.yaml`], not the other way around; if they
disagree, trust the YAML and fix this table" — directly against the live
`routines/routines.yaml`.

**Found real drift.** `routines.yaml`'s Executor trigger cron is `"0 0 * * *"` (1 run/day,
00:00 UTC only) as of PR #1348 (2026-08-25, the third same-day cadence cut that freed a
slot for a new `toomingsolutions/appforge-ci` trigger). But `docs/WAYS-OF-WORKING.md`'s
Executor registry row still read `00:00/05:00/14:00 UTC, every day (3/day)` — stale since
at least the first of that day's three cadence cuts (PRs #1334, #1342/#1343, #1348 each
dropped the account-wide k8s-anywhere slot count 4→3→2→1 to fund
`keebridge`/`skoor-ai`/`appforge-ci` respectively) and never caught, because
`scripts/routines-check.sh` only verifies `routines.yaml` itself was applied to the live
trigger — nothing cross-checked this doc's separate prose copy of the same fact.

This is the same drift *class* `tests/routine-schedule-spread.bats` already guards for
inside `routines.yaml` itself (see its own "actual cron hour count matches its own
declared 'Exactly N runs/day' policy comment" test, added after PR #1344 found the exact
same kind of stale-count bug when the 3→2 cut landed) — just a second, previously
unguarded copy of the fact, in a different file.

## Fix

1. **`docs/WAYS-OF-WORKING.md`** — corrected the Executor row's `Cadence · Model` cell
   from `00:00/05:00/14:00 UTC, every day (3/day) · Sonnet 5` to
   `00:00 UTC, every day (1/day) · Sonnet 5`, matching `routines.yaml`'s current
   `cron: "0 0 * * *"` and `model: claude-sonnet-5`.
2. **`tests/routine-schedule-spread.bats`** — added a new
   `@test "docs/WAYS-OF-WORKING.md's Executor registry row cadence matches
   routines.yaml's actual cron"` mirroring the existing self-checking pattern in the same
   file: it locates the Executor's row via its `trigger_id` (not a hardcoded row index),
   derives the expected fire-count and fire-time list from `routines.yaml`'s cron hour
   field, and fails if either the row's `(N/day)` count or its literal fire-time string
   doesn't match — so this specific drift class (a cadence cut lands in `routines.yaml`
   but this doc's separate copy of the fact isn't updated) cannot silently recur. This
   is a mechanical recurrence guard per CLAUDE.md's bugfix-prevention rule, following the
   repo's existing `scripts/<thing>-check.sh`-adjacent pattern of deriving the expectation
   from the source of truth rather than hardcoding a second literal.

No other file touched — this is not a `sync/*` (doc-drift-author) task, since that
routine's own prompt explicitly excludes ADR/CHARTER/`WAYS-OF-WORKING.md` edits from its
scope; per ROADMAP rule #9 this kind of doc-drift-plus-guard is executor-sanctioned,
same-run work.

## Verification

`bats tests/routine-schedule-spread.bats` — 5/5 pass (new test included). Full
`make ci` — green, exit 0, no `not ok` in the bats stream (2911 assertions passed, per
the run's own tail output).

## PR

auto/ways-of-working-cadence-table-drift-fix
