# Planner note — 2026-08-10 (Grafana alerting RFC grooming)

**Reached via:** `executor.prompt.md` STEP 6b, PLANNER fallback, fifth cycle this run
(after `auto/external-secrets-chart-2-9-0`, `auto/pyroscope-chart-2-2-1`,
`plan/alerting-rfc-gap`, and `arch/alerting-rfc-week33`). The three standing Now/next
items remain gated on unconfirmed maintainer-confirmation issues #631/#633/#1034 —
re-checked, unchanged since 2026-08-07.

**Intake grooming:** still exactly the three standing `[Action required]` confirmation
issues, already correctly labeled. Nothing to groom.

**RFC grooming:** the prior cycle's ARCHITECT-fallback pass (`arch/alerting-rfc-week33`,
#1085) opened RFC #1084 with a concrete, unambiguous decision (Grafana Unified
Alerting, four named rules with exact PromQL, visual-only, no notification receiver).
Per planner.prompt.md STEP 2b, `rfc`-labeled architect issues are explicitly in scope
for grooming without waiting on anything further — the RFC's own Decision + Acceptance
criteria sections are the spec. Groomed it directly into one 🟢 *Now / next* item
(`auto/grafana-alerting-rules`) carrying the exact four rules, their PromQL, and the
`for:` durations verbatim from the RFC — no further sizing decision needed, single-PR
shape, clusterless-deliverable (structural bats assertions on the provisioning YAML,
no live cluster needed).

Struck through the old 🟡 entry in the Cross-cutting hardening section with a
"Groomed ↗" pointer, matching every other resolved-RFC item's convention in that
section.

**Why this run stops at PLANNER rather than falling through further:** this is a real
planner deliverable — a 🟢 item is now sitting at the top of *Now / next*, ready for
this run's own next cycle (STEP 8) to build and merge as `auto/grafana-alerting-rules`
without waiting for a future run.

**No `[Action needed]` PR this cycle** — real backlog-grooming work was produced.
