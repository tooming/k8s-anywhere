# Replace the dead "idle issue" fallback across every routine prompt with a `[Action needed]` PR

(CHARTER **Core Values** §"Docs & dashboards don't drift" + governance correctness;
user-filed issue #569 — **no prerequisites, executor may pick up immediately**; this
is a workflow/governance fix per CLAUDE.md's "governance... and workflow (routines,
CI, Makefile, hooks) are all yours to propose, implement, and merge", not an ADR/RFC
-gated technical choice). Verified directly against the actual repo state (not
assumed, ADR-0004): `scripts/idle-issue-guard-check.sh`, wired as a `PostToolUse`
hook on `mcp__github__issue_write`/`mcp__github__add_issue_comment` in
`.claude/settings.json` (matcher block ~line 147), unconditionally flags **any**
issue title/body containing the standalone word "idle" (regex `\bidle\b|\bno
work\b|nothing to do|no actionable`) and instructs the routine to close the issue
and undo the action. Every routine's own documented "never end empty-handed"
terminal fallback creates or refreshes an issue whose title contains "idle" as a
standalone word — `executor.prompt.md` STEP 6b ("executor idle — needs work"),
`planner.prompt.md` STEP 4 (same title), `janitor.prompt.md` STEP 6 ("janitor idle
— no cleanup found"), `triager.prompt.md` STEP 6 ("triager idle — no untriaged
issues"), `doc-drift-author.prompt.md` STEP 7 ("doc-drift idle — docs are in
sync"), `upgrade-drafter.prompt.md` STEP 7 ("upgrade idle — everything at latest"),
`learning-post-writer.prompt.md` STEP 7 ("learning idle — quiet week, no post") —
every one of these is dead code: the moment a routine executes its own documented
last resort, the hook fires and tells it to reverse the very action its own prompt
just told it to take. This is the concrete gap issue #569 names ("If there are some
actions needed from the repo owner, then leave an open PR, starting with [Action
needed]...").

Fix, applied uniformly: replace each "file/refresh a `<role> idle — ...` GitHub
issue" terminal step with — open (or refresh, if a matching one is already open) a
PR on the role's own branch prefix whose only content is a new
`docs/backlog/YYYY-MM-DD-action-needed-<slug>.md` file stating precisely what is
blocked and, if applicable, exactly what maintainer action (outside the repo, e.g.
confirming a live-cluster state, setting a CI secret) would unblock it. Title the
PR `[Action needed] <one-line summary>` (never containing the word "idle"). Run the
normal self-review + self-merge contract on it like any other PR — it is a real,
`make ci`-trivial diff (a single new markdown file), so it merges the same run; the
`[Action needed]` prefix makes it a low-noise, filterable signal in the
maintainer's normal PR list, not a blocked state. This satisfies rule #9's "every
run ships a PR" **literally** (a PR, not an issue) instead of relying on a
mechanism the repo's own hook already disables.

**Delivered as PR 1 of 2:** the combined seven-file diff crossed the ~400
changed-line budget (WAYS-OF-WORKING.md §3), so this PR fixes
`executor.prompt.md` + `planner.prompt.md` only — the two roles STEP 6b's fallback
chain actually reaches — plus `tests/action-needed-fallback.bats` covering those
two files as the recurrence guard. The remaining five roles (janitor,
doc-drift-author, upgrade-drafter get the same PR-based fix; triager and
learning-post-writer need a different fix since they declare themselves PR-less by
design) are split into a new ROADMAP follow-up item, `auto/action-needed-pr-fallback-2`.

Closes #569.

## PR

https://github.com/tooming/k8s-anywhere/pull/578
