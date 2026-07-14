# Planner run 2026-07-14 — bluegreen bats + ADR-0019 gap

**Context:** The executor's "Now / next" lane was fully starved — all five unchecked 🟢
items require live-cluster maintainer confirmations (`cosign-enforce-flip` needs a `.sig`
tag confirmed in Artifactory; `capstone-pipeline-rewire` and `decommission-artifactory`
need the Harbor 12 GB footprint gate; `capstone-deployment-removal` needs an e2e Kargo
promotion confirmation). No ungroomed RFC issues exist (only open issue is #390, the idle
escalation from the prior run).

**Gap analysis performed:**
- No incoming architect items in `docs/roadmap/incoming/`.
- CHARTER vs ROADMAP diff: all CHARTER Goals and Objectives have items already in the
  backlog. The only open O4/O6 items are the live-cluster-gated ones above.
- Two `make ci` coverage gaps identified that are immediately buildable:

## Items added to Now / next

### 1. `tests/dr-bluegreen.bats` — structural test gate for bluegreen DR scripts

**Source:** CHARTER Goal "DR / blue-green on a single host". The six bluegreen scripts
(`dr-bluegreen.sh`, `bluegreen-up.sh`, `bluegreen-frontdoor.sh`, `bluegreen-down.sh`,
`bluegreen-probe.sh`, `dr-bluegreen-promote.sh`) and `gitops/bluegreen/green-root.yaml`
have no structural bats test in `make ci`. The `bluegreen-probe.bats` only unit-tests
the probe math (uptime %/outage calculation) — it doesn't assert the scripts exist, are
executable, or that the zero-downtime thresholds (`MIN_UPTIME=99.0`, `MAX_OUTAGE=2.0`)
can't be silently deleted. Mirrors the `dr-restore.bats` → `tests/dr-restore.bats`
pattern. Branch hint: `auto/dr-bluegreen-bats`.

### 2. ADR-0019 amendment — add `add-default-runasnonroot` to the Initial ClusterPolicy table

**Source:** ADR-0019 §"Initial ClusterPolicy set" lists only 4 policies but
`gitops/kyverno/policies/` has 5 since `add-default-runasnonroot.yaml` was added to close
the Harbor admission gap (`goharbor` sets container-level but not pod-level `runAsNonRoot`;
`require-pod-security-restricted` validates at the pod level). The ADR table and the
"All four policies" count are both stale. `tests/kyverno-add-default-runasnonroot.bats`
already exists and tests the policy correctly — only the ADR doc needs updating.
Branch hint: `auto/adr-0019-runasnonroot-row`.

## Idle issue #390 status

Issue #390 ("executor idle — needs work") reflects the live-cluster gate state that
remains true; these two new 🟢 items refill the lane for the next executor run so the
lane is no longer empty, but the original blocked items are still waiting on the maintainer.
