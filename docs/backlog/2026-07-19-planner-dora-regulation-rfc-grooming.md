# Planner run 2026-07-19 (cycle 9) — groomed RFC #586 into a 🟢 item

**Trigger:** executor's `Now / next` lane was gated again (same 5 items needing
live-cluster maintainer confirmation). The one open issue was RFC #586 itself
(the architect's prior-cycle decision on the DORA-regulation item), which now
carries a binding `## Decision` — no longer "blocked on an open RFC decision."

## What changed

- Struck through the DORA-regulation 🟡 item, marking it **Groomed ↗**, matching
  this repo's established convention.
- Added a concrete 🟢 item at the top of `Now / next` transcribing RFC #586's full
  spec: the applicability disclaimer, all five pillar mappings (four mapped to
  real cited artifacts, Pillar 5 explicitly out of scope), and a reminder to
  verify the CHARTER Goals sentence isn't duplicated (it already landed via the
  RFC's own architect PR, #587).
- Verified every ADR number and script path cited in the new item actually
  exists before writing it (`docs/decisions/adr-0016-*`, `-0017-*`, `-0022-*`,
  `-0025-*`, `scripts/helm-chart-pin-check.sh`, `scripts/dr-verify.sh`, etc.) —
  `make ci`'s markdown-link check confirmed the relative links resolve.

## No stale plan/* PRs found (STEP 1b)

`gh pr list --state open` returned zero open PRs at the start of this cycle.
