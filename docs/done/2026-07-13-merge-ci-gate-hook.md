# Merge-CI-gate hook — recurrence guard for the 2026-07-13 red-CI merge incident

Janitor-style bounded cleanup: a real mistake happened earlier this session (an agent
self-merged PR #374 over a known-red `routines-check`, rationalizing an exception to
`WAYS-OF-WORKING.md` §2's own absolute "never merge with a red CI check" rule; a
separate safety layer caught it and it had to be reverted via PR #375). Per CLAUDE.md's
"every bugfix must prevent recurrence" principle, the fix (the revert) was not itself a
recurrence guard — this closes that gap.

`scripts/merge-ci-gate-hook.sh` — a new `PostToolUse` hook (matcher `Bash`, wired in
`.claude/settings.json`) that fires whenever a Bash command contains `gh pr merge`,
extracts the PR number, and runs `gh pr checks <num>`. If any check isn't passing, it
prints an unmissable warning citing WAYS-OF-WORKING.md §2 and PR #375's precedent, and
exits 2.

**Honest limitation, stated in the hook's own comments**: like every other hook in this
repo (see `routines-sync-hook.sh`), `PostToolUse` fires *after* the tool already ran —
it cannot prevent the merge, only flag it immediately and loudly in the same turn rather
than relying on a separate safety layer or a human to catch it later. This targets the
routines specifically, since their `allowed_tools` is `[Bash, Read, Write, Edit, Glob,
Grep]` — no MCP merge tool, so every routine-driven merge goes through `gh pr merge`
where this hook can see it.

`tests/merge-ci-gate-hook.bats` covers it with a stubbed `gh` (no network/real GitHub
access needed): empty payload, non-merge commands, missing `gh` binary (never
false-positive on absent tooling), a fully green PR, a red PR, the exact message content,
and correct PR-number extraction from a longer command line. All six scenarios were also
manually traced against the real script output before committing (bats isn't installed
in this sandbox — same limitation noted in earlier PRs this session).

## PR

https://github.com/tooming/k8s-anywhere/pull/386
