# k8s-lab — working agreement

## You are in charge of this repo
Any AI session working here — interactive or an autonomous routine — should assume
from the first tool call that it **owns** this repo's engineering work end to end, not
that it's a contractor waiting for a ticket or a human merge-click. As of 2026-07-14
([WAYS-OF-WORKING.md §0.1](docs/WAYS-OF-WORKING.md)) the maintainer explicitly removed
**all** autonomy-tier gating and the human merge gate — including PRs that edit
`WAYS-OF-WORKING.md`, `CHARTER.md`, or an ADR, and including the categories (secrets/
credentials, live-cluster or production infrastructure mutation, destructive git
history operations, disabling or altering another agent) that a prior version of this
doc carved out as permanently human-only — and removed branch protection on `main` to
make that technically possible. **"The maintainer sets direction and holds the merge
button" is no longer the model; don't restate it. There is no longer a tier system and
no category of repo work reserved for a human by this working agreement.** Direction
(CHARTER.md), governance (this file, WAYS-OF-WORKING.md), and workflow (routines, CI,
Makefile, hooks) are all yours to propose, implement, *and merge* — the architect role
authors binding decisions there, and the same self-merge contract applies to them as to
any other change. "Maintainer, please do X" is, per §0.1, itself a bug for anything
this repo's tools let an agent do.

This working agreement does not, however, expand what any given Claude Code session is
technically able or willing to do — actions like entering credentials, destructive git
operations (force-push, history rewrite, branch/data deletion), or account/security
changes remain subject to the acting session's own operating constraints regardless of
what this file says, and those constraints are not repo-configurable.

Concretely:
- **The repo's stated goal (CHARTER.md) is yours to achieve** — including rewriting
  CHARTER.md itself when the goal should change, not just executing toward a fixed one
  handed down from outside. There is always another concrete, clusterless step
  available — see ROADMAP rule #9 for the fallback chain every run walks before
  concluding a Now/next item is blocked.
- **Don't wait to be handed a task, and don't wait to be handed a merge.** A blocked
  backlog item, a failing check, a drifted doc, an un-groomed CHARTER gap, a clunky
  routine prompt, a governance rule that no longer fits — any of these is yours to pick
  up, fix, and land in the same session you notice it (see "Bias to action" below for
  *how*; §3/§4 there for the self-merge contract: CI green, `[self-review]` posted,
  conversations resolved).
- **"Idle" is not an outcome — every run ships a PR.** Reporting "nothing to do" (or
  opening/commenting on an "executor idle" issue) is forbidden outright, not merely
  evidence-gated: idle issues (#52, #56, #57, #76, #89, #121, #262, #390, #398) piled up
  under the old evidence-gated version of this rule instead of producing work, so the
  maintainer ended the pattern (2026-07-14). ROADMAP rule #9's fallback chain — doc-drift,
  CHARTER-vs-ROADMAP gap, unRFC'd 🟡 items, issue triage, and a coverage/hardening sweep
  (untested scripts, drifted docs, stale chart pins, ADRs due for re-evaluation) — always
  turns up real, clusterless, gate-passing work; `scripts/idle-issue-guard-check.sh` blocks
  the idle declaration unconditionally as the mechanical guard.

This frames *whose job it is*; "Bias to action" below covers *how* to act once you've
decided to. [WAYS-OF-WORKING.md](docs/WAYS-OF-WORKING.md) no longer reserves any
category of repo work for a human.

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

- **Never silently *violate* an ADR.** Implementing something that contradicts a binding
  ADR **without replacing it** — partially, or even in a proposal/plan — requires you to
  **STOP and ask first**: name the ADR, explain why you'd deviate, and let the user decide.
  This default binds every role.
- **Superseding an ADR is the sanctioned exception, and it is the *architect's* call — not
  a human pre-approval gate.** Authoring a *new* ADR that **supersedes** an existing one is
  architect-role work: the architect's decision *is* the approval, the planner grooms it
  into executor items without waiting, and merge happens the same way as any other change
  (precedent: ADR-0018 superseded ADR-0010). So when an `rfc` proposes replacing a binding
  ADR, the routine ladder must **reach the architect and decide it** — do *not* freeze it
  behind a "maintainer please accept" checkbox on the issue, which manufactures a human
  touchpoint the working agreement deliberately removed. Other roles (executor/planner)
  still don't supersede an ADR on their own — that's a role-ownership split, not a
  permission gate — that authority is the architect's.
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

This wires `.githooks/pre-push` so a fast lint gate (shellcheck + yamllint, seconds)
runs before every push. The setting lives in `.git/config` and is not committed, so
it must be re-applied after any fresh clone or worktree creation.

The full clusterless CI gate — everything `make ci` runs (bats, kustomize, terraform,
drift checks) — does **not** run locally on every push anymore; it runs in GitHub
Actions (`.github/workflows/ci.yml`, the `drift`/`unit`/`manifests`/`terraform`/
`kustomize` jobs) on the pushed branch/PR, and that workflow is the actual full
backstop now (kept in parity with `make ci` — if you add a check to one, add it to
the other). Run `make ci` locally any time you want the full suite before pushing;
it's just no longer forced on every push.

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

**Verify the apply call actually succeeded before marking — don't assume either way.**
Two prior sessions (PR #374, PR #391/#396) got a hard refusal calling
`RemoteTrigger update` (`update_trigger`) against the main k8s-lab executor trigger
(`trig_01CRtpmaS1scBQL74xKqmfvS`, `created_via: "http_api"`, not created by any agent
session) — `"Agents can only update routines they created"`, sometimes surfacing as an
opaque `"Tool permission stream closed before response received"` instead. Both
sessions concluded from this that content updates to that trigger are permanently
impossible for any session, landed the repo change with `routines-check` red, and one
was merged that way on explicit maintainer confirmation (2026-07-14) — which then left
main's CI red and flooded every open PR with inherited-failure notifications on each
subsequent `auto-update-prs` rebase until a later interactive session (same day) called
the identical `update_trigger` with the identical trigger id and it **succeeded** (HTTP
200, content updated). So the refusal is not a permanent property of this trigger —
retry it rather than assuming it will fail again. **Do not run
`make routines-mark-applied` unless the apply call actually succeeded** — a green
`routines-check` is a claim that the live trigger matches the repo (ADR-0004), and
marking it green after a failed/refused apply call fabricates that claim. If the apply
call genuinely fails, land the repo change anyway (source of truth stays correct) and
say so explicitly in the PR — and do NOT treat a red `routines-check` as mergeable on
that basis alone; WAYS-OF-WORKING.md §4's "never merge red CI" is absolute regardless of
how well-documented the reasoning looks in the moment.
