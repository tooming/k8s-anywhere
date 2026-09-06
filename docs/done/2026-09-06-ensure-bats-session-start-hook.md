# `scripts/ensure-bats-hook.sh` — auto-install `bats` at session start so `make ci`'s unit-test gate can't silently self-skip in an autonomous session

CLAUDE.md's bugfix-recurrence-prevention rule; JANITOR-fallback cleanup 2026-09-06,
reached via `executor.prompt.md` STEP 6b after the "Now / next" lane was
re-confirmed fully gated this cycle (issues #633/#1229 unchanged) and
PLANNER/ARCHITECT/TRIAGER/DOC-DRIFT-AUTHOR all came up empty again. Found live this
same run: two `upgrade/*` version-bump PRs
(`upgrade/kro-0.9.3-to-0.9.4`, `upgrade/grafana-12.10.4-to-12.11.2`) both passed a
local `make ci` that silently skipped `tests/securitycontext-kro.bats`'s hard-coded
exact-chart-pin assertion because `bats` wasn't installed in this remote clusterless
sandbox — `scripts/test.sh`'s existing local-vs-CI skip is a fair convenience for a
human contributor, but this session's *entire* self-review contract IS `make ci`
(WAYS-OF-WORKING.md §0.1's self-merge model, no other backstop) — recurring twice in
one run makes it a real class of bug, not a one-off, per CLAUDE.md's own
bugfix-recurrence rule.

## What was done

Added `scripts/ensure-bats-hook.sh`, a best-effort `SessionStart` hook (installs
`bats` via `apt-get` if missing, silently no-ops if `apt-get`/network/permission
isn't available — never blocks the session) wired into `.claude/settings.json`.
Once `bats` is on `PATH`, `scripts/test.sh`'s own existing local/CI branch naturally
takes the "run the real suite" path for the rest of the session — no change needed
to `test.sh` itself.

Added `tests/hook-scripts-ensure-bats.bats` (its own file per
`tests/hook-scripts-coverage.bats`'s frozen-monolith rule — new hook-script coverage
must not be appended to that shared file) covering:

- the script exists and is executable;
- it exits 0 and reports "already installed" when `bats` is present (the actual path
  this very bats run itself exercises — self-verifying);
- it exits 0 even with no `apt-get` on `PATH` (never blocks the session on a
  degraded/offline environment);
- it is actually wired into `.claude/settings.json`, and that file is still valid
  JSON after the edit.

## Why this is in scope for a JANITOR cycle

Mechanical-over-skills: per CLAUDE.md, every bugfix needs a mechanical guard against
recurrence, not a note to remember. The gap here isn't a single bad line of code —
it's an environmental footgun (an autonomous session's local validation silently
skipping a real gate) that had already bitten this same run twice before being
caught. A `SessionStart` hook removes it by construction: the next remote session
that opens this repo gets `bats` installed automatically (best-effort), so `make
ci`'s unit-test step runs for real from the first `make ci` call onward, rather than
depending on every future session noticing the "· bats not installed — skipping"
line and remembering to install it themselves.

## Result

`make ci` passes green end-to-end (2900+ bats assertions, including the 5 new
`tests/hook-scripts-ensure-bats.bats` assertions, 0 failures). `.claude/settings.json`
remains valid JSON. No `gitops/` change — this is tooling/session-config only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1448
