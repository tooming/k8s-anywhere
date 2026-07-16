# ROADMAP "Now / next" preamble — fix stale O1/O2 status

Doc-drift fallback per ROADMAP rule #9, same triage pass that found the
dashboard-coverage gap (`docs/done/2026-07-16-dashboard-coverage-cert-manager.md`).

## Gap found

The `### Now / next` section's preamble (the guidance every executor/planner run reads
first) still described **CHARTER Objective O1** ("Tier 1 next-wave deployed") as "the
highest-priority outstanding objective" and gave pickup ordering for Kyverno, Velero,
Argo Rollouts, and Trivy Operator as if they were still unbuilt — all four have long
been auto-synced with their own ADR, dashboard, and bats coverage, and CHARTER.md's own
"Always-on next wave" section already says so (`built`). The same preamble described an
"O2 tail" (PSS-restricted for `moto`/`ack-system`/`lab-gateway`, NetworkPolicy for
`tidb`/`tidb-admin`, "two coverage-loop recurrence guards") as still pending; grepped the
backlog and found every one of those items already `[x]`. A stale preamble like this
actively costs future sessions time — it's the first thing read, and it pointed at
already-finished work instead of the real remaining gate (Objective O4 + the ADR-0024
Harbor/Artifactory migration).

## What shipped

Rewrote the preamble to state plainly that O1 and O2 are both done (citing CHARTER.md's
own O1 record), point at what's actually still open (O4 image-signing enforcement, the
Harbor/Artifactory migration and its dependents), and added an explicit pointer back to
rule #9's split-the-gate judgment for when every remaining item is gated — this session
needed to lean on that judgment twice (`auto/harbor-registry-secret-prep`,
`auto/harbor-kargo-egress-prep`) after all five `Now / next` checkboxes turned out
gated, and the preamble is the natural place to remind the next run of that rather than
re-discovering it from scratch.

## Verification

`bash scripts/roadmap-check.sh` passes (no inline planner-note format triggered). Full
`make ci` green.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
