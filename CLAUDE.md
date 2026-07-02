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

## The lab must be free to run
Every tool the lab depends on must run on a **free / open-source tier** — no paid
licenses, no trial-gated features, no "contact sales" tiers. Before proposing OR
adopting any software, **verify the specific capability you need exists in the free/OSS
edition** — an OSS edition existing is not enough; the *feature* must be in it (e.g.
Artifactory **OSS ≠ Pro** — replication and several repo types are Pro-walled; Harbor's
single free edition has no such wall — see ADR-0011/ADR-0024). If the capability is only
in a paid tier, that tool is disqualified; pick a fully-free alternative. This binds
every role, including the autonomous routines.

## Architecture decisions are binding
Before proposing OR implementing any technical/tooling choice, consult
`docs/decisions/` (the ADRs). They are binding, not advisory.

- **Never silently *violate* an ADR.** Implementing something that contradicts a binding
  ADR **without replacing it** — partially, or even in a proposal/plan — requires you to
  **STOP and ask first**: name the ADR, explain why you'd deviate, and let the user decide.
  This default binds every role.
- **Superseding an ADR is the sanctioned exception, and it is the *architect's* call — not
  a human pre-approval gate.** Per [WAYS-OF-WORKING.md §2](docs/WAYS-OF-WORKING.md) (Yellow
  tier), authoring a *new* ADR that **supersedes** an existing one is architect-tier work:
  the architect's decision *is* the approval, the planner grooms it into executor items
  without waiting, and the maintainer's only gate is the **merge button** on the resulting
  `arch/*` PR (precedent: ADR-0018 superseded ADR-0010). So when an `rfc` proposes replacing
  a binding ADR, the routine ladder must **reach the architect and decide it** — do *not*
  freeze it behind a "maintainer please accept" checkbox on the issue, which manufactures a
  human touchpoint the working agreement deliberately removed (§0: "the merge button is the
  maintainer's ONLY touchpoint"). Lower-tier roles (executor/planner) still never supersede
  an ADR on their own — that authority is the architect's.
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

## Bias to action — don't ask needless questions
The user delegates **outcomes, not steps**. Do **not** stop to ask permission or
confirmation for anything that is obviously useful and inside the goal you were given
(opening an issue/PR, applying a fix, running a verification, cleaning up). Just do it
and report what was done. No "want me to…?" / "should I…?" mid-flow — that offloads a
decision the user already made and reads as stalling.

Surface a choice **only** when it is a genuine fork the user alone can resolve — an
irreversible or outward-facing action with real trade-offs, or ambiguous requirements
that change *what* gets built — and even then prefer picking the sensible default and
saying so over interrupting. Never end a turn on a question when there's an obvious next
action to take instead. This binds every role, including the autonomous routines.

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

`routines-check` only proves the file matches `.routines-applied` — it **cannot** prove
the *live* trigger carries that content (CI has no claude.ai token). The hole that left:
the cloud executor has **no `RemoteTrigger` tool**, so it can edit a routine prompt, run
`make routines-mark-applied`, stay green, and the live trigger silently drifts (it did —
#251/#263). That footgun is removed structurally by `scripts/routines-author-check.sh`
(`make routines-author-check`, in `make ci` + the GitHub Actions `drift` job): it **fails
any executor-authored change — `auto/*` branch or `Claude <noreply@anthropic.com>` commit
— that touches a routine file.** So only interactive sessions (which can apply) edit
routine files; from an autonomous run, open an issue for a human instead.
