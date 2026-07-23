# [Action needed] Now/next still gated; CHARTER-precision sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments.

## This cycle's fresh angle

A third distinct lens (after cycle 4's upstream-version sweep and cycle 5's
dashboard-coverage completeness check): spot-verified CHARTER.md's own
measurable Objective claims against the actual mechanical gates that back
them, rather than assuming the prose is accurate.

- **O3** ("`make dr-restore` recovers every stateful namespace ... in under
  10 minutes"): confirmed `tests/dr-restore.bats` actually asserts all four
  namespaces (`data`, `tidb`, `capstone`, `vault`), the 600s budget constant,
  a shared `budget-check` lib, and a hard failure path when the budget is
  exceeded — the claim is backed by a real gate, not just prose.
- **O1** ("met ahead of its 2026-12-31 date"): spot-checked one of the four
  claimed components (Kyverno) has its own ADR (ADR-0019), a real-metric
  dashboard (`lab-kyverno.json`), and `make ci` bats coverage — consistent
  with the claim.
- No discrepancy found between CHARTER's stated objective status and the
  actual gates enforcing it.

Conclusion: this lens also comes up empty — CHARTER's claims check out.

## Prior cycles this run (context, not idle)

PR #672/#673/#674 (Envoy Gateway v1.8.3 bump, full RFC→plan→build loop),
PR #675 (cycle 4 honest record, upstream sweep), PR #676 (cycle 5 honest
record, dashboard-coverage sweep).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue.

This note is this cycle's honest record. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
