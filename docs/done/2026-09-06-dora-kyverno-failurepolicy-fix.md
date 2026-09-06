# Fix a stale ADR-0004 violation in `docs/dora-audit-readiness.md`'s Kyverno criticality-tier row

ADR-0004 (no fabricated content — dashboards/outputs must show real,
auto-discovered state); JANITOR-fallback cleanup 2026-09-06, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
gated this cycle (issues #633/#1229 unchanged) and PLANNER/ARCHITECT/TRIAGER/
DOC-DRIFT-AUTHOR/UPGRADE-DRAFTER all came up empty or too risky this cycle
(ArgoCD's chart 10.5.0 → 10.8.0 spanned multiple minor releases and this remote
session's page-fetch tooling could not reliably diff its large `values.yaml`
across tags — skipped rather than asserting safety it couldn't verify).

## What was found

`docs/dora-audit-readiness.md`'s Kyverno criticality-tier row claimed:

> Every policy in `gitops/kyverno/policies/` sets `failurePolicy: Ignore`
> (fail-open, confirmed directly in `verify-image-signatures.yaml`)

Verified directly against the real file (ADR-0004): `verify-image-signatures.yaml`
explicitly sets `failurePolicy: Fail`, not `Ignore` — it was flipped from
`Ignore`/`Audit` to `Enforce` + `Fail` on 2026-08-18 (per that file's own header
comment and ADR-0019's Re-evaluation log, closing CHARTER Objective O4's
admission-rejection criterion). The DORA doc's row was written before that flip
landed and never updated afterward — a real, concrete instance of the exact
"doc claims something the repo state no longer matches" failure mode ADR-0004
exists to prevent.

## What was done

Corrected the row to:

1. State the real, current fact: `verify-image-signatures.yaml` sets
   `failurePolicy: Fail`, verified directly, not assumed.
2. Honestly flag the other 4 `ClusterPolicy` files
   (`add-default-runasnonroot`, `add-default-seccomp`, `disallow-latest-tag`,
   `require-pod-security-restricted`) — none of them set `failurePolicy`
   explicitly, so their actual webhook behavior on a Kyverno outage depends on
   Kyverno's own admission-controller default. This session could not
   independently verify that default from a live cluster or a reachable
   upstream doc (kyverno.io is proxy-blocked in this sandbox), so it is
   explicitly NOT asserted either way — matching the ADR-0004 caution pattern
   this repo already uses elsewhere for facts it can't directly confirm.
3. Kept the row's overall **P1** tier unchanged: an outage during that
   undetermined-`failurePolicy` window is still, at minimum, a security-relevant
   gap for the 4 unset-`failurePolicy` policies (fail-open would silently
   disable enforcement) even with `verify-image-signatures` itself now
   fail-closed — the tier's justification just no longer repeats a claim that
   was already false for one of the five files.

No bats test depended on the old wording (checked `tests/dora-audit-readiness.bats`
directly — no `failurePolicy` references), so no test changes were needed.

## Why this is in scope for a JANITOR cycle

This run had already delivered two `upgrade/*` version bumps (kro, grafana) and
a mechanical recurrence-prevention fix (`ensure-bats-hook.sh`) this same cycle
chain. With PLANNER/ARCHITECT/TRIAGER/DOC-DRIFT-AUTHOR all confirmed empty and
a risky ArgoCD chart bump deliberately skipped rather than attempted without
reliable diffing, a documentation-accuracy sweep against ADR-0004 turned up this
real, previously-undetected drift — a smaller-scoped but still genuine, real,
verifiable fix, not manufactured filler.

## Result

`make ci` passes green (2929+ bats assertions, 0 failures — this change touches
only prose in `docs/dora-audit-readiness.md`, no gitops/test-file changes
needed). No `gitops/` change.

## PR

https://github.com/tooming/k8s-anywhere/pull/1449
