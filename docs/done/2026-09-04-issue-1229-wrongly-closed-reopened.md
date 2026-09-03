# Issue #1229 was wrongly closed alongside PR #1403 — reopened, ROADMAP rule #11 hardened

A prior cycle this run merged PR #1403 (the RBAC half of issue #1229's
`KUBECONFIG`-secret ask) and posted a comment on #1229 explicitly stating
"Still open per the `[Action required]` convention" — but, in the same
breath, made a direct state-change call closing the issue anyway. No
`Closes #1229`/`Fixes #1229` keyword appears anywhere in PR #1403's title,
body, or squash-merge commit message, so this was not GitHub's own
keyword-triggered auto-close; it was a mistake in the executor's own
sequence of actions.

No live-cluster confirmation had actually happened: the `KUBECONFIG` secret
still isn't set, and no run of the `verify-rejection` job has ever executed.
A closed `[Action required]` issue asserts a confirmation that didn't
happen — exactly the kind of false state ADR-0004 exists to prevent.

## What was done

1. Reopened issue #1229 via the GitHub API.
2. Posted a comment on the issue explaining the mistake, with the exact
   evidence (no closing keyword found, timestamps line up with a direct
   close call) and reconfirming what's still needed
   (`docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md`'s 5-step
   checklist).
3. Hardened `ROADMAP.md` rule #11 with an explicit, procedural recurrence
   guard: never close a standing `[Action required]` issue except via the
   real confirmation it names, and re-read an issue's own state after any
   cycle that touches it, before ending the turn.

## Why this is procedural, not mechanical (CLAUDE.md's own escape hatch)

This class of mistake — a wrong `issue_write`/`gh issue close` call — has no
code-level guard: `make ci` cannot intercept a GitHub API call an agent
makes mid-cycle. Per CLAUDE.md's own guidance ("if a class genuinely cannot
be guarded mechanically, say so explicitly... don't silently ship a
symptom-only patch"), the fix here is the strongest available: a discipline
written directly into the binding operating rule every future cycle reads,
naming this exact incident so it isn't abstract.

No `gitops/` or code change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1404
