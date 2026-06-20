# k8s-lab — working agreement

## Every bugfix must prevent recurrence (fix + mechanical guard)
A bugfix is **not done** when the symptom is gone. Every bugfix has two deliverables:

1. **Fix it** — resolve the immediate problem.
2. **Stop the whole class from recurring** — add a *mechanical* guard so the same kind of
   bug cannot silently come back: a CI gate, a git/PostToolUse hook, a test, or a
   structural change that removes the failure mode entirely (the strongest option —
   eliminate the footgun, don't just detect it).

This is the default for **all** bugfixes; you don't need to be asked. It is the
mechanical-over-skills principle applied to fixes: enforce the invariant in code/CI,
**never** via "I'll remember" or a forgettable note. Prefer, in order: (a) make the bug
*impossible* by construction; (b) a CI gate wired into `make ci`; (c) a hook that nudges
at edit/push time; (d) a test that fails on regression. Mirror the existing drift-guard
pattern — `scripts/<thing>-check.sh` + `make <thing>-check` in `make ci` + a `PostToolUse`
sync-hook + bats coverage in `tests/drift-detectors.bats` (see `readme-check`,
`roadmap-check`, `securitycontext-tests-check`).

If a class genuinely **cannot** be guarded mechanically, say so explicitly in the PR and
explain why — don't silently ship a symptom-only patch.

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

## Git hooks — run once per clone
At the start of every session (including worktrees), run:

```
make install-hooks
```

This wires `.githooks/pre-push` so that `make ci` runs before every push. The setting
lives in `.git/config` and is not committed, so it must be re-applied after any fresh
clone or worktree creation.

## Always open a PR
After pushing changes to the feature branch, **always open a pull request** for them
(unless the user says otherwise). Don't wait to be asked.

## Keep other PRs rebased after every push
PR merges happen on GitHub (not via local `git pull`), so the `post-merge` hook
never fires automatically. After every push to a feature branch, run:

```
make rebase-prs PUSH=1
```

This rebases all open PR branches onto the current main, preventing merge conflicts
from accumulating. Branches with content conflicts are flagged and left unchanged for
manual resolution — but the pre-push hook already blocks pushing a branch that's behind
main, so catching up early is always easier than resolving conflicts later.

The `SessionStart` hook also runs this automatically at the start of each session.

## Routines: edit-then-apply is one atomic step
Editing a `routines/*.prompt.md` file (or `routines.yaml`) in-repo does **not** change
the live claude.ai trigger. The "apply" step that pushes the new content to the trigger
backend can only happen from inside a Claude Code session via the `RemoteTrigger update`
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
