# [Action needed] Now/next still gated; DR-doc + NP-coverage sweep clean (cycle 8)

**Date:** 2026-08-20
**Cycle:** 8th cycle this run

## What's blocked

Unchanged: the "Now / next" lane holds the same three items every prior
cycle this run re-confirmed gated (the two GitLab→Forgejo migration items,
and the capstone `Deployment` removal on issue #633).

## What was tried this cycle

1. **`docs/DR.md` staleness spot-check** — this run's earlier cycles found
   and fixed three real stale claims in core docs (`docs/00-architecture.md`'s
   Kyverno mode and dashboard count, `docs/dependency-register.md`'s Loki/
   Tempo dates). Applied the same lens to `docs/DR.md` (the DR runbook).
   Found GitLab references throughout (`make dr-test`'s scope table, the
   blue/green runbook, the "DR irony" section) — but unlike the fixed doc
   claims, these accurately describe what the actual `Makefile`/scripts
   still do today (GitLab is still what `make dr-test`/`make up` bootstrap
   and recover, per the same investigation ROADMAP's gitlab-rename item
   already did). Left untouched — rewriting these to say Forgejo would
   describe behavior the code doesn't have yet (the same reasoning PR #1284
   used for `docs/00-architecture.md`'s GitLab references).
2. **NetworkPolicy/PSS coverage heuristic re-check** — attempted to
   independently re-verify CHARTER Objective O2's "every namespace has
   default-deny NetworkPolicy + PSS-restricted (or an ADR-cited carve-out)"
   claim by grepping `gitops/` for each of the 28 namespaces' NetworkPolicy
   manifests. The ad-hoc heuristic (directory-glob-based) was unreliable —
   it flagged every single namespace as missing coverage, including ones
   `make ci`'s own `networkpolicy`/`securitycontext` bats suites and the
   "every networkpolicy/ and governance/ leaf directory is covered by its
   ApplicationSet list-generator" drift check already confirm are covered.
   Trusted the existing mechanical checks (which passed clean this cycle)
   over a flawed ad-hoc re-implementation rather than filing a false
   finding.

Both standing `[Action required]` issues (#633, #1229) re-checked — no new
comment on either.

## Why this is the honest deliverable

Two real attempts this cycle: one correctly found the DR doc's GitLab
references are accurate-to-code (not a bug, matching this run's own
established precedent), the other correctly abandoned a flawed heuristic
rather than report a false positive. Recording honestly per ROADMAP rule #9
and `executor.prompt.md` STEP 6b/STEP 8. Going straight back to STEP 1.
