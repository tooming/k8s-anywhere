# Planner note (2026-07-12) — CHARTER learning-path gaps: DR/blue-green + Kargo

## Run context

Scheduled planner run. All five unchecked "Now / next" items are blocked on
maintainer-confirmation prerequisites (verifyImages Enforce flip, Harbor capstone
re-wire budget sign-off, Rollout exercised confirmation). No open issues to groom;
no `docs/roadmap/incoming/` files pending. Fallback to gap analysis per STEP 6b.

## Gap found

CHARTER's **Goals** section includes "DR / blue-green on a single host" as an
explicit learner goal. The learning-path section in `docs/00-architecture.md` (steps
0–9) covers Velero backup/restore (step 8) and Argo Rollouts canary (step 7) but
**does not mention blue-green DR** at all. The Makefile already has the targets
(`make dr-bluegreen`, `make dr-bluegreen-promote`, `make dr-bluegreen-down`) and
`docs/DR.md` has the full runbook — only the learning-path narrative is missing.

Similarly, Kargo (ADR-0023) appears in the "Who-does-what" table in
`docs/00-architecture.md` and is deployed as an on-demand component, but there is
no learning-path step that tells a learner what Kargo does, how it composes with Argo
Rollouts, or how to exercise it (`make kargo-up`). This is a learner-experience gap
for CHARTER Goal "progressive delivery with promotion gates."

## Item added to ROADMAP.md

New 🟢 item added to the "Now / next — Always-on platform" section (after the
`auto/cilium-agent-metrics` item, before `### Heavy on-demand components`):

  `docs/00-architecture.md` — add learning-path steps for DR/blue-green and GitOps
  promotion (Kargo) (branch `auto/architecture-doc-learning-path-update`)

The item is tagged 🟢 (docs-only, no prerequisites, executor may pick up immediately).
It specifies two additions to `## Suggested learning path`:
- Step 10: DR / blue-green (`make dr-bluegreen` → traffic cut-over → `make dr-bluegreen-promote`)
- Step 11: GitOps promotion pipelines (Kargo Warehouse → dev auto-promote → prod manual gate)

## Why these are separate from step 7 / step 8

- Step 7 (Argo Rollouts) = in-cluster traffic shaping (blue ↔ canary on the *same* cluster)
- Step 8 (Velero) = data restore from backup on the *same* cluster
- Step 10 (blue-green DR) = full-platform rebuild on a *fresh* cluster with live traffic cut-over
- Step 11 (Kargo) = cross-stage image promotion (dev → prod), not per-pod traffic shaping

They are complementary but address distinct failure modes and delivery controls.

## ADR compliance

No ADR violations. Item is docs-only. Kargo is already in scope (ADR-0023). Blue-green
DR is in scope (CHARTER Goal; Makefile targets already exist). No new tooling proposed.

## No issues to close

No open issues were groomed this run (none queued in the GitHub intake).
