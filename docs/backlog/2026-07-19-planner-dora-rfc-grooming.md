# Planner run 2026-07-19 (cycle 5) — groomed RFC #580 into a 🟢 item

**Trigger:** the executor's `Now / next` lane was gated again this cycle (the same 5
items needing live-cluster maintainer confirmation). The planner's issue-grooming
lane was exhausted (0 open issues — both #569 and #576 groomed earlier this run). The
architect fallback role (previous cycle, PR #581) resolved the one remaining 🟡 item
(DORA-metrics) into RFC #580 with a binding `## Decision`. That RFC is no longer
"blocked on an open RFC decision" — it's real, green-able work to promote, so
STEP 6b's PLANNER no-op clause ("backlog is genuinely healthy") does not apply.

## What changed

- Struck through the DORA-metrics 🟡 item in *Cross-cutting hardening & quality*,
  marking it **Groomed ↗** per this repo's established convention for RFC'd items
  (mirrors every prior `~~🟡~~ ... Groomed ↗` entry in that section).
- Added a new 🟢 item at the top of `Now / next`: `scripts/dora-metrics.sh` +
  `make dora-metrics`, transcribing RFC #580's binding spec (all four metric
  definitions, the script's exact behavior including the ADR-0004 "insufficient
  data" requirement, the bats coverage shape, and the `Closes #580` instruction) so
  the executor can implement directly without re-deriving anything from the RFC.

## Side note (not part of this PR's diff)

While closing out cycle 4's architect PR (#581), its body's literal text "Closes
#580 once merged is not applicable here" tripped GitHub's issue-linking parser (it
doesn't parse English negation, just pattern-matches "Closes #NNN") and auto-closed
RFC #580 on merge, before any of its acceptance criteria were implemented. Reopened
it immediately with an explanatory comment — the groomed 🟢 item above now correctly
carries `Closes #580` itself, to close it for real once the implementation lands.

## No stale plan/* PRs found (STEP 1b)

`gh pr list --state open` returned zero open PRs at the start of this cycle.
