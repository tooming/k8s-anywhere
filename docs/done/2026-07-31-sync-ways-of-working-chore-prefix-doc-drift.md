# Fix stale `chore/*` branch-prefix classification in docs/WAYS-OF-WORKING.md

`docs/WAYS-OF-WORKING.md` §3's "Branch prefix signals origin" list grouped `chore/*`
with the human prefixes `feat/*`/`fix/*` ("Agent prefixes are reserved — humans don't
use them" implying `chore/*` is safe for humans) — stale since PR #251 (2026-06-22)
added the janitor role, which uses `chore/*` as its own agent branch prefix
exclusively:

- `routines/janitor.prompt.md` STEP 1b and STEP 6 both use `chore/<short-slug>` for
  real cleanups and `chore/action-needed-<slug>` for its idle-fallback record.
- `scripts/stale-prs-check.sh`'s `AGENT_PREFIXES=(auto plan arch upgrade sync chore)`
  already treats `chore` as an agent prefix.
- `scripts/rebase-open-prs.sh` and `scripts/prune-stale-branches.sh`'s branch-matching
  regex (`(auto|arch|chore|claude|copilot|plan|upgrade|sync|digest)/`) already treat
  it the same way.
- WAYS-OF-WORKING.md's own §1 registry text ("`janitor.prompt.md` ... never separately
  triggered — same model, fallback-only") already lists janitor among the agent
  routines, contradicting §3's classification three sections later in the same file.

Every mechanical enforcement point already agrees `chore/*` is an agent prefix; only
the prose table in §3 was stale.

## Fix

Moved `chore/*` into the agent-prefix list (attributed to janitor), and added a note
that `digest/*` is a dead prefix (industry-news-writer retired 2026-06-13, folded
into the architect per §1's own text) kept only for recognizing any stray leftover
branches. Left `feat/*`/`fix/*` as the only human prefixes.

No behavior change — purely a documentation-precision fix reconciling the prose
table with what every script and routine prompt already does.

`make ci` passes (2345 assertions, 0 failures).

## PR

https://github.com/tooming/k8s-anywhere/pull/941
