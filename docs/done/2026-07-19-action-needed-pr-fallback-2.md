# `[Action needed]` PR fallback — remaining five routine prompts

(CHARTER **Core Values** §"Docs & dashboards don't drift"; PR 2 of 2, follow-up to
`auto/action-needed-pr-fallback` — **no prerequisites, executor may pick up
immediately**). Applied the same fix to `janitor.prompt.md` STEP 6,
`doc-drift-author.prompt.md` STEP 7, and `upgrade-drafter.prompt.md` STEP 7:
replaced each "file/refresh a `<role> idle — ...` GitHub issue" terminal step with
opening/refreshing a PR titled `[Action needed] <one-line summary>` on the role's
own branch prefix (`chore/action-needed-<slug>` for janitor,
`sync/action-needed-<slug>` for doc-drift-author, `upgrade/action-needed-<slug>`
for upgrade-drafter) whose only content is a new
`docs/backlog/YYYY-MM-DD-action-needed-<slug>.md` note — same shape as the
executor and planner fix in PR 1.

`triager.prompt.md` and `learning-post-writer.prompt.md` needed a *different* fix,
not the uniform one — verified against both files before writing (ADR-0004): both
declare themselves PR-less by design (`triager.prompt.md`'s own CONSTRAINTS:
"Labels only... no PRs"; `learning-post-writer.prompt.md` writes exactly one
`docs/learnings/` file per run, no code — opening an `[Action needed]` PR from
either would contradict their own stated contract). Instead, for both: dropped the
issue-filing fallback entirely and treated "nothing to triage" / "quiet week,
nothing pedagogically interesting merged" as an accepted no-op, mirroring
`routines/architect.prompt.md` STEP 9's existing precedent ("a no-op is acceptable
for the architect"). Each already ends with (or now explicitly states) a one-line
summary as the honest record of the run — triager's CONSTRAINTS already require
`Triaged: N — needs-domain: M — skipped: K`.

Extended `tests/action-needed-fallback.bats` with the same two-assertion pattern
(no `issue create`/`issue_write`, contains `[Action needed]`) for
`janitor.prompt.md`, `doc-drift-author.prompt.md`, and `upgrade-drafter.prompt.md`;
added assertions for `triager.prompt.md` and `learning-post-writer.prompt.md`
confirming neither contains `issue create`/`issue_write`, plus a
"never opens a PR" assertion for `triager.prompt.md` specifically (the only one of
the two that is unconditionally PR-less — `learning-post-writer.prompt.md` still
opens PRs for real posts, just not for its no-op case). Updated the bats file's
header comment: all seven routine prompts are now covered, dropping the "tracked
follow-up, not yet covered" note from PR 1.

All seven `routines/*.prompt.md` files are now free of the dead issue-based idle
fallback. See `docs/done/2026-07-19-action-needed-pr-fallback.md` (PR 1) for the
full verified finding (scripts/idle-issue-guard-check.sh unconditionally blocks
any GitHub issue/comment carrying the standalone word "idle").

## PR

https://github.com/tooming/k8s-anywhere/pull/579
