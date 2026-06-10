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

## Routines: edit-then-apply is one atomic step
Editing a `routines/*.prompt.md` file (or `routines.yaml`) in-repo does **not** change
the live Codex.ai trigger. The "apply" step that pushes the new content to the trigger
backend can only happen from inside a Codex session via the `RemoteTrigger update`
tool — there is no CI mechanism that does it.

So: **when you edit any `routines/*.prompt.md` (or `routines.yaml`), you MUST**, in the
SAME session, before the PR is considered complete:

1. Call `RemoteTrigger update` against the matching trigger from `routines/routines.yaml`,
   sending the new file's content as the prompt.
2. Run `make routines-mark-applied` to refresh `.routines-applied` (the in-repo snapshot
   the drift detector reads).

`make routines-check` (wired into `make ci`) fails the PR if a routine file's sha differs
from `.routines-applied` — that's the enforcement. A `PostToolUse` hook
(`scripts/routines-sync-hook.sh`) nudges you the moment you save an edit, so the apply
step is never silently forgotten. Background: see [routines/README.md](routines/README.md).
