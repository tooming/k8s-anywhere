# Planner note — 2026-08-07 (GitLab / LGTMP-internals ADR gap)

**Reached via:** `executor.prompt.md` STEP 6b, PLANNER fallback. All three
`Now / next` items (`auto/cosign-enforce-flip`, `auto/o4-ci-rejection-gate`,
`auto/capstone-deployment-removal`) remain gated on unconfirmed
maintainer-confirmation issues #631/#633 — re-checked both issues' full comment
threads this run; the most recent comments (2026-08-07, same day) show real,
substantial live-cluster progress (multiple root causes found and fixed —
Cilium drift, stale Harbor creds, a missing GitLab Runner, a sealed Vault, a
Harbor NetworkPolicy port mismatch, a stuck-Terminating Kargo namespace, a
missing Warehouse `constraint` field) but neither issue has an actual
confirmation comment yet, and a related standing issue (#1034, disk-pressure
precondition) is also still open. Both gates remain unsatisfied.

**Intake grooming:** `gh issue list --state open` (via the GitHub MCP tools —
no `gh` CLI available in this remote session) shows exactly 3 open issues, all
three of them the standing `[Action required]` confirmation issues above
(#631, #633, #1034) — none are `rfc`-labeled or ungroomed user work requests.
Nothing to groom this run.

**Gap analysis:** every other item in `ROADMAP.md`'s Backlog section is
already `[x]` — confirmed by grepping for `^- \[ \]` across the whole file
before this run's edit, which returned only the three gated `Now / next`
items above. There was no un-RFC'd 🟡 item and no un-promoted 🟢 item
anywhere else in the file to move into `Now / next` (the "promote a
green-able item forward" instruction in STEP 6b's PLANNER fallback has
nothing to act on this run — the backlog isn't starved for want of grooming,
it's starved because the only remaining work is gated on a live-cluster fact).

Widened the lens (per STEP 8's "different angle" guidance) to
`docs/dependency-register.md`, which already carries a self-flagged, unactioned
gap in its "Keeping this in sync" section: **GitLab** and the observability
stack's internals (**Mimir, Loki, Tempo, Pyroscope, Alloy, kube-state-metrics,
node-exporter**) have no dedicated ADR, so they structurally cannot appear in
the register's own table. The register's text names this as "architect-scoped
work... not a mechanical doc-sync fix" but nothing in `ROADMAP.md` was tracking
it as an actionable item — it was a dead-end prose note. Added it as a new 🟡
item in the "Cross-cutting hardening & quality" section (this is real,
CHARTER-aligned work — Core Value "Decisions written down, rejected options
off-limits" — not manufactured filler); it needs an architect RFC to decide
scope (per-tool vs. one combined LGTMP ADR, and whether GitLab folds into
ADR-0001 or gets its own file) before an executor can build it.

**Why this run stops at PLANNER rather than falling through to ARCHITECT:**
this constitutes a real planner deliverable per `planner.prompt.md` STEP 4
("gap analysis... produced ANY ROADMAP changes" → deliver as the plan PR) —
the item is now visible and RFC-ready for the architect role to pick up on a
future cycle (this run's *next* cycle, per STEP 8, will re-check the lane
fresh and can invoke ARCHITECT directly if this item is still the topmost
un-RFC'd 🟡 item found).

**No `[Action needed]` PR this cycle** — real backlog-grooming work was
produced, so the last-resort fallback doesn't apply.
