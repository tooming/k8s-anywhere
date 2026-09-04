# Fix `tests/routine-schedule-spread.bats` drift after the executor cron 3→2 runs/day cut, add a self-checking guard

Bugfix, not a ROADMAP item: found `main`'s CI (`unit` job) red on the very
first cycle of this autonomous run, after PR #1341 (this run's own first
cycle) inherited a pre-existing regression from `main`. Root-caused directly
(no assumption, ADR-0004): PR #1342/#1343 (a separate, concurrent interactive
session) changed `routines/routines.yaml`'s cron from `"0 0,5,14 * * *"`
(3 runs/day) to `"0 0,5 * * *"` (2 runs/day, freeing a third account-wide
slot for a new `tooming/skoor-ai` executor trigger) without updating
`tests/routine-schedule-spread.bats`'s two now-stale hardcoded assertions:
`spread >= 12` hours (impossible for a 2-value, 5-hour-apart schedule) and
`count -eq 3` (the schedule now legitimately fires 2 times/day). Both failed
on every `make ci`/CI run since those PRs merged.

(A significant side-investigation happened before finding this: the CI
`unit` job's failure signature — bats exiting 1 with no obviously-adjacent
diagnostic near the end of a ~2900-line TAP stream — initially looked like
runner-level flakiness, and was reproduced locally against the exact CI
runner OS/bats package while investigating. That reproduction was real, but
the diagnosis was wrong: the two `not ok` lines were present all along,
just buried mid-stream past a `tail`-only check. No behavioral change was
shipped from that investigation — it was fully reverted once grep-ing the
complete log for `^not ok ` surfaced the real cause. Recorded here so a
future session hitting an apparently-inexplicable clean-looking bats
failure checks the FULL log for `not ok` lines before suspecting bats/bash
internals.)

## Fix

Updated `tests/routine-schedule-spread.bats`'s two assertions to match the
now-intentional, already-documented (`routines.yaml`'s own header comment)
2-runs/day schedule:
- "spans at least 12 hours" → "spans at least 4 hours" (still meaningfully
  guards against clustering for a 2-value schedule; the old 12h threshold
  assumed a 3+-value schedule that no longer exists here).
- "fires at most 3 times a day" (hardcoded `-eq 3`) → replaced with a
  self-checking assertion that derives the expected count from
  `routines.yaml`'s own "Exactly N runs/day" sentence instead of a second
  hardcoded literal, so this specific drift class — cron cadence changes but
  this test's hardcoded expectation doesn't — can't silently recur even if a
  future cadence change again forgets to touch this test file: the check now
  fails on either side going stale relative to the other, not just when this
  file itself falls behind.

## Verification

`bats tests/routine-schedule-spread.bats` — 4/4 pass. Full `bash
scripts/test.sh` — 2898/2898 pass, zero `not ok`, exit 0 (confirmed via
direct `grep -c '^not ok '`, not just a clean-looking tail). `make ci` —
green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1344
