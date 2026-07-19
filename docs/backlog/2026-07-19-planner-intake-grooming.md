# Planner run 2026-07-19 — intake grooming

**Trigger:** the executor's own ROADMAP lane was fully gated this run — every one of
the five remaining unchecked `Now / next` items (verifyImages Audit→Enforce flip,
its dependent O4 CI gate, the Harbor capstone rewire, the Artifactory decommission,
and the legacy capstone Deployment removal) carries a maintainer-confirmation
prerequisite tied to live-cluster state (a `.sig` tag actually pushed, the Harbor
footprint actually measured, a Kargo promotion actually exercised) that this remote
clusterless session cannot verify. None had a further splittable safe slice — each is
already the tail-end gated slice of a previously-split RFC (RFC #214's cosign split,
RFC #297's Harbor migration, the `auto/capstone-rollout` follow-up promise). Per
ROADMAP rule #9, that "genuinely can't find a live-state-safe slice" conclusion is
recorded here rather than fabricating a slice that doesn't exist.

Escalated through `executor.prompt.md` STEP 6b's fallback chain to the **PLANNER**
role (the first blocker: two ungroomed intake issues existed with no `groomed`/
`wontfix`/`question` label).

## Intake grooming — 2 issues groomed

- **#569 "Workflow changes"** ("If there are some actions needed from the repo owner,
  then leave an open PR, starting with [Action needed]..."). Verified against the
  actual repo state (not assumed, ADR-0004): `scripts/idle-issue-guard-check.sh`,
  wired as a `PostToolUse` hook on GitHub issue create/comment calls, unconditionally
  blocks any issue whose title/body contains the standalone word "idle" — which is
  exactly what every routine's own documented last-resort fallback issue title uses
  (`executor idle — needs work`, `janitor idle — no cleanup found`, etc., across all
  seven routine prompt files). Every one of those fallback paths is dead code today.
  Sized into one 🟢 `Now / next` item: replace the issue-based idle fallback with a
  `[Action needed]`-titled PR across all seven prompt files (split into two PRs if the
  combined diff crosses ~400 lines — executor + planner first, since STEP 6b's chain
  only reaches those two). No RFC needed — this is a workflow/governance fix per
  CLAUDE.md, not a technology choice.
- **#576 "DORA-compliancy"** ("Make the repo DORA-compliant"). Sized as 🟡 — parked in
  the *Cross-cutting hardening & quality* section with five concrete open questions
  (what counts as a deployment/change-failure/restore-event in a clusterless,
  self-merging GitOps repo; where the metrics get computed and surfaced, since this
  isn't live-cluster data like every other dashboard; whether it becomes a new CHARTER
  Objective) that the architect fallback role must resolve via a binding RFC before
  the executor can build anything. Not groomed to 🟢 — this is a methodology decision,
  not an implementation detail a planner run should pick unilaterally.

Both issues closed with the `groomed` label after this PR opened, per planner STEP 6.

## No stale `plan/*` PRs found (STEP 1b)

`gh pr list --state open` returned zero open PRs at the start of this run — nothing to
recover.
