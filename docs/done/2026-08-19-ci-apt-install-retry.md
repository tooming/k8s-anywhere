# CI: bounded-retry apt-get installs in `lint` and `unit` jobs

**Date:** 2026-08-19

## What

`.github/workflows/ci.yml`'s `lint` job (`Install shellcheck + yamllint`)
and `unit` job (`Install bats`) each ran a single unbounded
`sudo apt-get update && sudo apt-get install -y -qq <pkgs>` call. Both are
now a 3-attempt loop, each attempt wrapped in `timeout 90` and run with
`DEBIAN_FRONTEND=noninteractive`, with a 5s backoff between attempts.

## Why

This exact failure mode is already documented at the top of `ci.yml` (PR
#648, 2026-07-21): a network-dependent install step can hang instead of
failing, silently consuming the job's entire `timeout-minutes` budget with
zero progress. The existing `timeout-minutes` mitigation turns that into a
visible failure, but recovery still requires a human/agent to notice and
manually re-run the job.

This run (2026-08-19) hit it three times in about 40 minutes: the `unit`
job's `bats` install hung once (PR #1257), then the `lint` job's
`shellcheck`/`yamllint` install hung on two consecutive attempts in a row
(PR #1259) — each attempt consuming the full 10-minute `timeout-minutes`
budget before being cancelled. Per CLAUDE.md's "every bugfix must prevent
recurrence" rule, retrying by hand a third time without addressing the
underlying pattern would just be the same manual recovery again.

## The fix

Bound each individual `apt-get` call to 90 seconds and retry up to 3 times
in-job, instead of one attempt bound only by the job's full
`timeout-minutes`. A hung mirror fetch now fails an individual attempt in
under 2 minutes and retries automatically within the same job run — no
manual re-run needed for the common case. `DEBIAN_FRONTEND=noninteractive`
also rules out an interactive prompt (e.g. a `tzdata`-style dpkg question)
as a hang cause, which a bare `apt-get -y` does not otherwise guarantee.

## Why no bats coverage

This is CI-runner-only behavior (`sudo apt-get` against a live package
mirror inside GitHub's hosted runner) — there is nothing to assert about it
from a clusterless bats sandbox that isn't already covered by
`ci-parity-check` (this fix doesn't add a new `scripts/*.sh` gate — the
retry logic is inlined in the workflow steps, not extracted to a script,
specifically so it isn't mistaken for a check `make ci` should also run).
Per CLAUDE.md: "if a class genuinely cannot be guarded mechanically, say so
explicitly" — a real end-to-end proof this actually reduces recurrence only
comes from watching subsequent CI runs, not a local test.

## PR

#1260
