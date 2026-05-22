# ADR-0004 — Dashboards/outputs show real, auto-discovered state

**Decision.** Never fabricate content presented as the lab's real state. No
"coming soon" placeholders, no hand-typed lists standing in for live data. Show
only what actually exists and is verified; prefer auto-discovery / live queries.

**Why.** The user reacted strongly to a Homepage portal padded with a hand-written
services list and a "Grafana — coming soon" tile for something not yet deployed.
Invented content is useless and erodes trust.

**Applies to.** Dashboards (the stack-health dashboard is real PromQL over live
metrics), status reports, and any output. Also: **verify before asserting** —
don't claim something is deployed/working without checking it.

**Status.** Adopted. The fabricated Homepage was removed in favour of the
metrics-driven Grafana stack-health dashboard.
