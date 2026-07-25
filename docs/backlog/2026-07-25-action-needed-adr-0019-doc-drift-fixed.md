# [Action needed] Now/next still gated; this cycle shipped a real ADR-0019 doc-drift fix

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, zero comments, `updated_at` unchanged
since 2026-07-21T05:34 UTC. No new ungroomed GitHub issues exist beyond
these three standing trackers, and `docs/roadmap/incoming/` is empty (no
pending architect items to absorb).

## This cycle's real progress (not idle)

Walked the STEP 6b fallback chain: planner (no ungroomed intake, no
`docs/roadmap/incoming/` files — nothing to groom), architect (no un-RFC'd
🟡 item exists), upgrade-drafter (prior same-day cycles already swept
dependency/chart pins clean, re-confirmed no new PR opened this cycle),
doc-drift-author (explicitly barred by its own prompt from touching
`docs/decisions/` — cannot act on an ADR-scoped finding) — landed on the
janitor lane, which found and fixed a real, verified doc-drift bug:

**PR #726** (`chore/adr-0019-argocd-carveout-doc-drift`, merged) —
`gitops/kyverno/policies/disallow-latest-tag.yaml`'s `argocd` carve-out
(added earlier today by commit `1659b5e` / PR #722, the #632 live-cluster
OOM/deadlock investigation) already had its own code comment and
`tests/kyverno.bats` coverage, but [ADR-0019](../decisions/adr-0019-kyverno-admission-engine.md)
— the binding doc the policy's own annotation cites — still only documented
the original `capstone` carve-out (issue #498). Added the `argocd` carve-out
to both ADR-0019 locations (policy table + Scope & exceptions), mirroring
the existing entry's structure and citing only facts verified directly
against the policy YAML (ADR-0004). Docs-only, behavior-preserving,
`make ci` green (all 7 GitHub Actions checks passed).

## This cycle's fresh angle beyond that fix

Before filing this note, cross-checked every other Kyverno policy's
`exclude`/namespace-scoping block against its ADR-0019 table description for
the same class of drift:

- `require-pod-security-restricted.yaml` and `add-default-runasnonroot.yaml`
  both carry a `namespaces: [kube-system, kube-public, kube-node-lease]`
  hard-coded exclude alongside their PSA-label-based exclusion — neither is
  individually called out in ADR-0019's table, but both are standard
  cluster-managed-namespace boilerplate (not a deliberate, reasoned carve-out
  like `capstone`/`argocd` — no "why"/flip-condition narrative applies), so
  documenting them would be noise, not signal. Not treated as a gap.
- `verify-image-signatures.yaml`'s registry scope
  (`artifactory.127.0.0.1.nip.io/**`) matches ADR-0019's description exactly
  — no drift (expected: the Harbor migration items are themselves still
  gated on #632, so nothing has moved yet).

No further gap found on this pass.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record — on top of one real merged PR
(#726) earlier in this same run — not a stopping point in principle;
`executor.prompt.md` STEP 8 would continue to the next cycle in a
longer-running session.
