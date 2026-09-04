# Complete the self-merge loop in all PR-producing routine prompts

`WAYS-OF-WORKING.md` §0.1 (2026-07-13, merged) already grants agents full merge
authority — no human merge gate, including PRs that edit governance files — but the
routine prompt files still told routines to stop at "open a PR" and wait ("Do NOT push
to main. Do NOT merge."). A prior session prepared the fix (PR #374) but it got
reverted because that session's `update_trigger` tool couldn't push the change to the
live executor trigger, and merging with a permanently-drifted live trigger and no way
to flag it was worse than reverting.

This lands the same completion (self-review → confirm CI green + conversations
resolved → `gh pr merge --squash --delete-branch`) across all six PR-producing
routines (`executor`, `planner`, `architect`, `upgrade-drafter`, `doc-drift-author`,
`janitor`) plus adds a missing self-review/merge step to `learning-post-writer` (which
never had one). The Red-tier boundary (secrets, live-cluster/production mutation,
destructive git history operations, disabling/altering another agent) is explicitly
preserved and restated in each prompt's constraints — this change is scoped to
completing already-adopted merge authority for ordinary PR work, nothing broader.

Also fixes a separate, pre-existing staleness discovered while editing the routine
registry table: `docs/WAYS-OF-WORKING.md` §1 and `routines/README.md` both described 8
separately-scheduled triggers, but only ONE (`trig_01CRtpmaS1scBQL74xKqmfvS`, the
executor) has actually been live since 2026-06-13 — the rest were retired that day and
absorbed into the executor's own fallback chain (confirmed via `list_triggers` against
the live backend). Both docs now match reality.

**Apply-step gap (documented, not silently worked around):** attempted `update_trigger`
against the live executor trigger with the new `executor.prompt.md` content. It failed
with `"Agents can only update routines they created"` — `trig_01CRtpmaS1scBQL74xKqmfvS`
was created via the claude.ai UI/API directly (`created_via: "http_api"`), not by any
agent's `create_trigger` call, so no session (interactive or not) can push new prompt
content to it via this tool; only `enabled:false` and cosmetic fields are permitted.
This is the same gap PR #374 hit, now documented precisely (exact refusal message) in
`CLAUDE.md` and `routines/README.md` so future sessions don't re-attempt the same call
expecting a different result. **`make routines-mark-applied` was deliberately NOT
run** — the snapshot file is a claim that the live trigger matches the repo (ADR-0004),
and that would be false. `routines-check` stays red until the maintainer applies
`executor.prompt.md`'s new content by hand through the claude.ai routines UI.

## PR

https://github.com/tooming/k8s-anywhere/pull/391
