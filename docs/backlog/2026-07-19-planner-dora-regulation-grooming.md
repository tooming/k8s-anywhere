# Planner run 2026-07-19 (cycle 7) — groomed issue #583 (DORA regulation) into a 🟡 item

**Trigger:** executor's `Now / next` lane was gated again (same 5 items needing
live-cluster maintainer confirmation). One open issue existed: #583, filed earlier
this same run after the maintainer clarified mid-run that issue #576's original
"DORA-compliant" ask meant the EU Digital Operational Resilience Act, not the
DevOps Research and Assessment metrics that had already been groomed/RFC'd/
implemented as `auto/dora-metrics` by this point in the run.

## What changed

Parked a new 🟡 item in *Cross-cutting hardening & quality*, transcribing #583's
analysis (applicability is genuinely unresolved — this lab is not an EU-regulated
financial entity; the five DORA pillars overlap meaningfully with practices the
lab already exercises; scope is CHARTER-Objective-level, not a single RFC).
Correctly sized as 🟡, not 🟢 — this needs an architect decision on which pillars
(if any) map to honest, non-overclaiming CHARTER work before any executor item can
be written.

## No stale plan/* PRs found (STEP 1b)

`gh pr list --state open` returned zero open PRs at the start of this cycle.
