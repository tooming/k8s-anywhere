# tests/routines-mark-applied.bats — close the writer-side coverage gap

ROADMAP rule #9's coverage/hardening fallback lane names "a script under `scripts/`
with no `tests/*.bats` coverage" as always-real, always-available work. Re-swept
`scripts/*.sh` (excluding the Makefile/tooling wrappers and `*-sync-hook.sh`
PostToolUse wrappers that stay thin/untested by established convention) and found
one remaining gap: `scripts/routines-mark-applied.sh`. `tests/routines-check.bats`
(added 2026-07-14) covers the *reader* — `routines-check.sh`, which diffs
`routines/*.prompt.md` / `routines.yaml` against `.routines-applied` — but nothing
covered the *writer* that produces `.routines-applied` in the first place.

`routines-mark-applied.sh` didn't have the `<THING>CHECK_ROOT` env-var override that
`readme-check.sh` / `roadmap-check.sh` / `routines-check.sh` all use to run against a
fixture tree instead of the real repo — without it, any bats test would have executed
the script against the real repo root and overwritten the actual tracked
`.routines-applied`, corrupting working-tree state as a side effect of running tests.
Added the same override pattern (`ROUTINESMARKAPPLIED_ROOT`, defaulting to the real
repo root when unset — no behavior change for `make routines-mark-applied`).

## Changes

- `scripts/routines-mark-applied.sh`: added `ROUTINESMARKAPPLIED_ROOT` override,
  mirroring `ROUTINESCHECK_ROOT`/`ROADMAPCHECK_ROOT`/`READMECHECK_ROOT`.
- New `tests/fixtures/routines-mark-applied/basic/routines/{executor.prompt.md,
  routines.yaml}` — a minimal fixture routines tree (bats copies it to a scratch
  `mktemp -d` per test, so no test run ever writes into the tracked fixture
  directory).
- New `tests/routines-mark-applied.bats` (6 assertions): script exists/executable;
  writes `.routines-applied` with the documented header comment; records the
  correct sha256 for each routine file; the written snapshot round-trips clean
  through `routines-check.sh`; a snapshot correctly detects and then clears drift
  after a real file edit + re-mark; and — the safety-critical assertion — running
  the script with the fixture override leaves the real repo's `.routines-applied`
  byte-identical.

`make ci` passes (bats/lint locally; full suite in GitHub Actions).
`make routines-check` still passes on the real repo (verified this run) — the
`ROUTINESMARKAPPLIED_ROOT` addition is purely additive/opt-in.

(auto/routines-mark-applied-bats-coverage)

## PR

<!-- filled in after opening the PR -->
