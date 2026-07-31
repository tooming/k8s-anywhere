# Fix stale "~28 ArgoCD apps" count in ROADMAP.md's intro

ROADMAP.md's "How the executor uses this file" preamble (line 14) still read
"the demo app — ~28 ArgoCD apps" in present tense ("The always-on stack is
already built ... ~28 ArgoCD apps"), even though CHARTER.md's own
"Always-on core" bullet was corrected from "~28" to "~33" on 2026-07-29
(issue #846, `docs/done/2026-07-29-charter-application-count-recount.md`) and
`docs/dora-audit-readiness.md`'s derived mention was fixed in the same PR.

That PR's own tracking note
(`docs/backlog/2026-07-29-action-needed-charter-application-count-stale.md`)
explicitly enumerated the other "~28" mentions it checked and deliberately
left alone as historical snapshots (ADR-0017's original RFC #83 context, and
a completed `[x]` item's body text now at ROADMAP.md:2582, which describes a
past state — "it now runs ~28 ArgoCD Applications" — at the time that item
was written). It never mentions or checks ROADMAP.md's own top-of-file intro
line, which is present-tense, not historical — so it was a genuine miss, not
an intentional exclusion.

Bumped ROADMAP.md line 14's "~28 ArgoCD apps" to "~33 ArgoCD apps" to match
CHARTER.md's corrected count. No other change. `make ci` unaffected (docs-only
edit; ROADMAP.md's own `roadmap-check.sh` planner-note gate is unaffected by
this line). This is planner-lane work (ROADMAP.md is the planner's exclusive
editable file) reached via the executor's STEP 6b escalation chain after the
entire live "Now / next" lane was found gated on maintainer-confirmation
issues #631/#633 with no live-state-safe slice to split off either gated
item, and a full CHARTER-vs-repo gap-analysis sweep (O6, O7, every ADR's
re-evaluation-log flip condition checked against live upstream, doc-drift,
test-coverage) turned up this single genuine finding.

## PR

See PR link once opened.
