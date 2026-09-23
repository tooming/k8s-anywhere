# k8s-lab — working agreement

## Architecture decisions are binding
Before proposing OR implementing any technical/tooling choice, consult
`docs/decisions/` (the ADRs). They are binding, not advisory.

- **Never** implement something that contradicts an ADR. If you think an ADR should
  be revisited, **STOP and ask first** — name the ADR, explain why you'd deviate, and
  let the user decide. Do not act against an ADR unprompted, even partially or in a
  proposal/plan.
- ADRs named `adr-NNNN-<chosen>-not-<rejected>.md` encode a **rejected** option — treat
  it as off-limits (e.g. ADR-0002: Garage, NOT MinIO).
- A `SessionStart` hook (`scripts/adr-context-hook.sh`) surfaces every ADR's decision at
  the start of each session — read it. A `PostToolUse` guard (`scripts/adr-guard-hook.sh`)
  flags edits to infra/code that reintroduce a rejected technology.
- ADR-0004: never fabricate content as real state; **verify before asserting** that
  something is deployed/working.

## Always open a PR
After pushing changes to the feature branch, **always open a pull request** for them
(unless the user says otherwise). Don't wait to be asked.

## Routines: pointer architecture — only routines.yaml needs "apply"
Editing a `routines/*.prompt.md` is a normal PR with **no apply step**: a live trigger's
`live_prompt` is a static pointer telling the run to read its `prompt_file` fresh from the
checked-out repo, so the edit is live the moment it merges to `main`. Only edits to
`routines/routines.yaml` still need the apply — `RemoteTrigger update` against the matching
trigger, then `make routines-mark-applied`, in the SAME session — because those fields are
what actually gets pushed to the live claude.ai trigger. `make routines-check` (wired into
`make ci`) fails the PR if `routines.yaml` differs from `.routines-applied`, and a
`PostToolUse` hook (`scripts/routines-sync-hook.sh`) nudges you when you save an edit to it.

The apply runs through Claude Code's `RemoteTrigger` tool; there is no CI mechanism that
does it. If your session has no such tool (a Codex CLI session, say), don't fake it: open
the PR with the `routines.yaml` change, say plainly in it that the apply is still pending,
and do **not** run `make routines-mark-applied` (that file asserts the live trigger matches
the repo). `routines-check` stays red — and a red check is never grounds to merge — until
the apply actually happens (from a Claude Code session, or by hand in the claude.ai UI).

This section is a short mirror, not the source of truth: the full procedure and the
failed-apply cases are in [CLAUDE.md](CLAUDE.md) (same heading) and
[routines/README.md](routines/README.md). If it ever disagrees with them, they win and this
section is the bug; `tests/drift-routines-checks.bats` keeps its heading tied to CLAUDE.md's
and fails if a prompt-file edit is again described as needing an apply.
