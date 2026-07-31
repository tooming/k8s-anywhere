# Fix branch-discovery regex gap in rebase-open-prs.sh / prune-stale-branches.sh

`scripts/rebase-open-prs.sh`'s no-`gh` fallback and `scripts/prune-stale-branches.sh`'s
branch-discovery both filtered remote branches with the regex
`(auto|arch|chore|claude|copilot)/` — silently missing `plan/*`, `upgrade/*`, `sync/*`,
and `digest/*`, four of the agent branch prefixes named in
[docs/WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md)'s "Branch prefix signals origin" list
(`auto/*` executor, `plan/*` planner, `arch/*` architect, `upgrade/*` upgrade drafter,
`sync/*` doc-drift author, `digest/*` industry-news writer).

## How this was found

Live, not theoretical: PR #936 (`sync/adr-0024-status-header-doc-drift`, opened earlier
in this run) fell three merges behind `main` with no automatic rebase ever catching it
up — every `git pull`'s post-merge hook (which shells out to `make rebase-prs`) reported
rebasing only `auto/*` branches in its "Branches to check" list, `sync/*` never appeared.
By the time this was caught (STEP 1b's stale-PR sweep), PR #936's `up-to-date` CI check
was failing outright, and its own `make ci` run had also caught a second, unrelated
stale-placeholder bug in its `docs/done/` file (fixed in that same PR, #936).

`scripts/prune-stale-branches.sh` has the exact same regex, so `plan/*`/`upgrade/*`/
`sync/*`/`digest/*` branches also never got pruned once merged or orphaned — the SAME
`sync/*` branch pattern that already bit `rebase-open-prs.sh` was silently
accumulating stale branches this script exists to clean up.

## Fix

Extended both regexes to `(auto|arch|chore|claude|copilot|plan|upgrade|sync|digest)/`
— every prefix from WAYS-OF-WORKING.md's list, plus the pre-existing `claude|copilot`
entries (kept for backward compatibility, not part of that list). Added a comment to
each script pointing at the other's identical regex, so future prefix additions (or a
prefix rename) are less likely to update one and forget the other.

## Recurrence guard

New bats test in `tests/rebase-open-prs.bats` ("discovers every agent branch prefix
from WAYS-OF-WORKING.md, not just auto/arch/chore") and `tests/prune-stale-branches.bats`
("recognises every agent branch prefix..."): each builds a fixture with one
`plan/*`/`upgrade/*`/`sync/*`/`digest/*` branch and asserts the script actually
discovers/reports it. Regressing the regex back to the narrower set fails both.

## Verification performed

`bats` is not installed in this sandbox (`make ci` skips unit tests locally, same as
every PR this run) — manually exercised both fixture scenarios against the real
scripts with a throwaway git repo (`init.defaultBranch=main`, matching the CI runner's
git config, confirmed as the actual cause of an initial false-negative in a local repro
using this sandbox's own `master`-default git config) and confirmed all four new
prefixes are correctly discovered/reported by both scripts before writing the bats
tests to codify the same scenario.

Behavior-preserving: no existing branch (`auto/*`, `arch/*`, `chore/*`, `claude/*`,
`copilot/*`) changes match status; the regex only gains new alternatives, none removed.

## PR

https://github.com/tooming/k8s-anywhere/pull/938
