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
and correct PR-number extraction from a longer command line.

## Two real bugs found and fixed after the initial push (CI caught both)

1. **Exit-code trust.** The hook originally treated any non-zero exit from
   `gh pr checks` as a failing check. GitHub-hosted runners ship a real (if
   unauthenticated) `gh`, so the "gh not on PATH" test found that real binary, got an
   auth-error exit code, and the hook flagged it as red CI — a false positive on the
   exact class of thing it exists to avoid. Fixed by matching the literal word "fail"
   as its own token in `gh`'s output instead of trusting the exit code.

2. **PATH leak into bats' own cleanup.** `bats` isn't installed in this sandbox by
   default; installed it via `apt-get install bats` to actually reproduce CI locally
   rather than keep guessing from log text. Root cause: `minimal_path_without_gh()`
   set `PATH="$MINPATH"` as a bare statement, which persisted for the rest of that
   test's bats subshell — including bats' own internal post-test cleanup (`rm`),
   excluded from the minimal tool set. This produced `rm: command not found` on a
   *non-numbered* line invisible to the TAP `ok`/`not ok` stream, yet still corrupted
   bats' overall exit code: all 1666 suite tests printed `ok`, the `1..1666` plan
   matched exactly, and CI still failed with no visible cause. Reproduced and confirmed
   locally byte-for-byte against the real CI log (`grep`ping for `rm: command not
   found` in both). Fixed by scoping `PATH="$MINPATH"` to the single `run` invocation
   (bash's per-command temporary-environment semantics) instead of mutating it for the
   rest of the test.

Both fixes verified locally post-`apt-get install bats`: the isolated file now runs
clean (`bats tests/merge-ci-gate-hook.bats` → `1..8`, all `ok`, exit 0).

## PR

https://github.com/tooming/k8s-anywhere/pull/386
