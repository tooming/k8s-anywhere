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
every PR this run), so the real GitHub Actions `unit` job was the actual test of the
new bats coverage — and it caught a real bug in the first version of these tests: the
prefix-iteration loops used `git checkout -b <name> main` (the explicit-start-point
form), which doesn't trigger git's remote-tracking auto-vivification the way a bare
`git checkout main` does. That form failed to resolve on both this sandbox's git
(defaults to `master`) *and* the real CI runner's git (confirmed live: CI failed on
the `plan` prefix with `fatal: 'main' is not a commit`) — the CI runner does **not**
default to `main`, contrary to an initial assumption. Fixed by checking out
`origin/main` explicitly (the same pattern this file's own pre-existing "active"
fixture already used), re-verified locally against this sandbox's real `master`-default
git before pushing again, and confirmed green on the actual GitHub Actions `unit` job
(all ~2350+ assertions passing, including the new tests) before merging.

Behavior-preserving: no existing branch (`auto/*`, `arch/*`, `chore/*`, `claude/*`,
`copilot/*`) changes match status; the regex only gains new alternatives, none removed.

## PR

https://github.com/tooming/k8s-anywhere/pull/938
