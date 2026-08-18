# Garage-failure drill (`make dr-garage-failure`)

CHARTER **Goals** §"operational-resilience discipline" + **Objective O3**'s
stateful-DR framing — DORA's Pillar 3 "digital operational resilience testing"
(TLPT concept). Executor pickup of the topmost 🟢 *Now / next* item, which this
same run had authored one cycle earlier via the PLANNER fallback role
(`executor.prompt.md` STEP 6b, PR #1239) after finding the lane fully gated on
unconfirmed maintainer-confirmation issues #631/#633.

## Item description (as it stood in ROADMAP.md)

**Simulate Garage unavailability — third DR fault-injection drill
(`make dr-garage-failure`).** Verified directly (not assumed, ADR-0004):
`docs/dora-audit-readiness.md` Q12 named this exact gap — after `dr-chaos.sh`
(pod-kill self-heal) and `dr-network-partition.sh` (NetworkPolicy-delete
self-heal) both shipped, Q12's own Gap line said "Simulating Garage
unavailability, as this question's original framing also suggested, remains a
real, separately-scoped future drill if wanted — a different failure domain
(storage-layer availability) from either drill here."
`gitops/storage/garage/statefulset.yaml` confirms Garage runs as a
single-replica (`replicas: 1`) `StatefulSet` (`app: garage`, namespace
`storage`) — the same "one pod, assert Kubernetes self-heals it" shape
`dr-chaos.sh` already exercises for capstone, just against a different
component and namespace, so this is a mechanical adaptation of a proven
pattern, not a new design.

Deliverables: `scripts/dr-garage-failure.sh` copying `dr-chaos.sh`'s structure
(four shared libs, `confirm_or_abort` gate with `DR_ASSUME_YES` bypass, a
justified `BUDGET_S`); a `dr-garage-failure` Makefile target, on-demand only
(NOT wired into `up`/`ci`/`dr-test`); `tests/dr-garage-failure.bats`
(clusterless structural, mirroring `tests/dr-network-partition.bats`'s shape);
a `docs/DR.md` subsection; and closing `docs/dora-audit-readiness.md` Q12's gap
line — including what's still *not* covered, so the gap stays honestly scoped.

## What was built

`scripts/dr-garage-failure.sh` — deletes the single running Garage pod in the
`storage` namespace, then polls until a replacement pod's container reports
ready within a **120 s** budget (matching `dr-chaos.sh`'s own budget: Garage's
StatefulSet has no readinessProbe override and no custom startup delay beyond
its own process init — config read, single-node layout confirm, S3/admin
listeners open — normally well under 30 s on a healthy node, so 120 s gives the
same 4× headroom without masking a real regression). Calls
`dr_log_result "dr-garage-failure.sh"` on both the PASS and FAIL exit paths.

Two correctness details carried over deliberately rather than re-derived:

1. **The readiness check reuses `dr-chaos.sh`'s own self-review-caught fix.**
   A pod being deleted keeps `status.phase=Running` throughout its
   `terminationGracePeriodSeconds` window, so the poll excludes the deleted
   pod's own name by field-selector *and* requires the replacement's actual
   container readiness — not just `phase=Running`, which a pod reaches before
   its readiness probe has passed. Reintroducing that bug would have made the
   drill report instant, meaningless "self-heal confirmed" on every run
   (see `docs/done/2026-08-13-dr-chaos-self-heal-check-fix.md`).
2. **`--wait=false` is correct here, and is the opposite of what
   `dr-network-partition.sh` needs.** This drill deletes a *pod*, which has a
   grace period worth not blocking on (`dr-chaos.sh`'s own reasoning);
   `dr-network-partition.sh` deletes a *NetworkPolicy*, which has no grace
   period, and its own self-review found `--wait=false` there caused a
   false-positive instant pass. `tests/dr-garage-failure.bats` guards the
   flag in *this* direction, mirroring `tests/dr-network-partition.bats`'s
   guard in the other — so a future copy-paste between the two drills can't
   silently flip either one.

`tests/dr-garage-failure.bats` — 15 clusterless structural assertions
(existence/executability, all four shared libs sourced, `confirm_or_abort`
present, `BUDGET_S` declared, the namespace + label selector matching the
**live** `gitops/storage/garage/statefulset.yaml` including its `replicas: 1`,
`dr_log_result` on both exit paths, the readiness-based poll shape, the
`--wait=false` guard, the Makefile target declared and NOT invoked from
`up`/`ci`/`dr-test`).

`docs/DR.md` — new "Garage-failure drill (`make dr-garage-failure`)"
subsection after the network-partition one; the results-log section's drill
count updated five → six. `docs/dora-audit-readiness.md` Q12 — Answer/Evidence/
Gap all updated: three fault types now covered across two components, with the
two genuinely-uncovered classes (multi-pod/quorum loss — N/A today, every
stateful component here is single-replica per ADR-0005; full node loss) named
plainly rather than the gap being declared closed outright.

## ADR-0004 caveat

This remote clusterless session authored and structurally verified the script
but has **not** executed it against a real cluster — same caveat as every other
DR-script addition in this repo. Rollback path: the script is on-demand only
(not wired into `up`/`ci`/`dr-test`), so nothing runs it implicitly; a failed
drill run leaves no cluster-state change beyond the one pod delete Kubernetes
itself already guarantees to recover from.

## PR

#1240 — https://github.com/tooming/k8s-anywhere/pull/1240
