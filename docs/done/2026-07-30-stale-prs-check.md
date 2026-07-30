# `scripts/stale-prs-check.sh` + `make stale-prs-check` — mechanical STEP 1b helper

CHARLIE's bug-fix-prevents-recurrence rule (CLAUDE.md): a bugfix isn't done when
the symptom is gone, it needs a mechanical guard so the same class of bug can't
silently recur. This is that guard for a class of bug that has now recurred
**three separate times** in this repo's history:

1. **PR #449** (2026-07-16) — went CI-green with nothing left but the
   self-review-then-merge step; the scheduled follow-up turn produced no
   action, and it sat open until the maintainer merged it by hand.
2. **PRs #914/#915** (2026-07-30) — both went CI-green with no `[self-review]`
   comment; caught and finished by this same run's own STEP 1b (a different,
   concurrent executor session had produced them).
3. **PR #921** (2026-07-30) — same pattern, also caught this run.

Every one of these was a PR that finished its work, went CI-green, and had
nothing left to do but self-review and merge — but the run that produced it
ended (context/turn/credit limit) before that last step fired. Every
producing routine's STEP 1b is the recovery path *("finish any stale
self-mergeable PR from a prior run before starting new work")*, but until now
that step was a hand-reconstructed `gh pr list --search "head:auto/
head:plan/ head:arch/ head:upgrade/ head:sync/ head:chore/"` query the acting
session had to get exactly right from memory every single cycle, then
cross-reference each match's checks and labels by hand — a "remember to
check" pattern, exactly what CLAUDE.md says a bugfix must never rely on.

## What changed

New `scripts/stale-prs-check.sh`: queries every open PR across all six agent
branch prefixes (`auto/`, `plan/`, `arch/`, `upgrade/`, `sync/`, `chore/`)
via the `gh` CLI, and flags any PR whose required checks are all green but
which has no `self-reviewed` label yet — exactly the "stranded, ready to
merge" signature all three incidents above shared. Degrades gracefully (exit
0, explanatory message) when `gh` isn't installed or isn't authenticated,
since this is a discovery aid for interactive/routine sessions, not a
`make ci` gate (CI runners don't need live PR state).

New `make stale-prs-check` target (mirrors the existing `make rebase-prs` /
`make prune-branches` utility-target style).

Updated STEP 1b in all six `routines/*.prompt.md` files (executor, planner,
architect, upgrade-drafter, doc-drift-author, janitor) to run
`make stale-prs-check` first, instead of only describing the manual `gh pr
list --search` query — the detailed manual fallback stays in each file as a
backup, but the shared script is now the primary path, so the search logic
lives in one tested place instead of being re-typed correctly by every role
every cycle.

New `tests/stale-prs-check.bats`: asserts the script exists/is executable,
documents the recurring footgun, covers all six branch prefixes, exits 0
cleanly with no `gh` on `PATH` (this repo's own `make ci` sandbox has no
`gh`), and that the Makefile target is wired and `.PHONY`.

No behavior change to anything else — this is additive tooling, not a
refactor of existing scripts. `make ci` passes (2340+ assertions, including
the 6 new `stale-prs-check.bats` assertions).

## PR

chore/stale-prs-check-guard
