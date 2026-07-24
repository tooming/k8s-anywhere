# Planner run 2026-07-24 — major-bump intake grooming

**Trigger:** the executor's own ROADMAP lane is fully gated this run — all five
remaining unchecked `Now / next` items still carry a maintainer-confirmation
prerequisite tied to standing issues #631/#632/#633 (unchanged since 2026-07-21).
Earlier in this same run, the UPGRADE-DRAFTER fallback merged three real same-source
patch/minor bumps (`auto`-equivalent `upgrade/*` PRs #701 rabbitmq, #702 pyroscope,
#703 grafana chart) and, per its own "skip major bumps, open an issue" rule, filed
two issues for major-bump candidates it explicitly declined to build directly: #704
(`kube-state-metrics` chart `7.8.1`→`8.0.0`) and #705 (`apache/kafka` client image
`3.9.2`→`4.3.1`, `gitops/inkless/kafka-load.yaml`).

Escalated through `executor.prompt.md` STEP 6b's fallback chain back to the
**PLANNER** role for a fresh cycle (the blocker: those two freshly-filed issues were
ungroomed intake with no `groomed`/`wontfix`/`question` label).

## Intake grooming — 2 issues groomed

- **#704** "kube-state-metrics chart major bump available: 7.8.1 → 8.0.0". Sized as
  🟡 — parked in the *Cross-cutting hardening & quality* section. Not groomed to 🟢
  despite the diff looking low-risk on inspection (the only breaking surface is a
  removed `CiliumNetworkPolicy` template variant this lab's `observability-ksm.yaml`
  never references) — a major-version bump is a bright-line "needs a human/architect
  call" case per `routines/upgrade-drafter.prompt.md`'s own rule, and a planner run
  isn't the right role to make that judgment call unilaterally either.
- **#705** "apache/kafka client image major bump available: 3.9.2 → 4.3.1
  (kafka-load, Inkless namespace)". Sized as 🟡 — parked alongside #704. This one
  has a real behavioral-risk profile (Kafka 4.x drops ZooKeeper mode entirely and
  changes client/protocol-negotiation defaults) that this clusterless session
  cannot verify against Inkless's Kafka-protocol implementation (ADR-0004) — an
  architect decision (or a documented hold, mirroring ADR-0013's Longhorn
  `1.12.0` hold) is needed before this is buildable.

Both issues closed with the `groomed` label after this PR opened, per planner
STEP 6 — the ROADMAP.md 🟡 entries are now the tracking mechanism; each entry links
back to its issue number for the full verification trail.

## No stale `plan/*` PRs found (STEP 1b)

`gh pr list`-equivalent (`mcp__github__list_pull_requests`, state open) returned
zero open PRs at the start of this cycle — nothing to recover.

## No further gap-analysis findings this cycle

No new CHARTER-vs-repo gaps found beyond the two issues above; the "Now / next"
lane's five gated items are unchanged from earlier cycles this run. No other open
issues exist beyond the three standing `[Action required]` confirmation trackers
(#631/#632/#633, deliberately never groomed — they're maintainer-confirmation
gates, not backlog items) and #704/#705 groomed here.
