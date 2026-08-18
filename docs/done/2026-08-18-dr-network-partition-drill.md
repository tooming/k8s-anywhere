# Network-partition drill (`make dr-network-partition`)

CHARTER **Goals** §"operational-resilience discipline" — DORA's Pillar 3 "digital
operational resilience testing" (TLPT concept); janitor-fallback cleanup,
`executor.prompt.md` STEP 6b, seventh cycle this run, reached after PLANNER/
ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all found nothing further this
cycle (Now/next lane still fully gated; ARCHITECT and PLANNER both delivered
earlier this run and had nothing new on re-check; UPGRADE-DRAFTER's one-PR-per-run
cap already spent; DOC-DRIFT-AUTHOR's actual scope — readme-check/lab-ui-check/
dependency-tree — clean; TRIAGER's only open issue already fully labeled).

## What was found

`docs/dora-audit-readiness.md`'s own Q12 answer names the exact scoped fix, the
same way it did for the original `dr-chaos.sh` drill (built 2026-08-04 via this
identical fallback pattern): "Cutting a NetworkPolicy or simulating Garage
unavailability, as this question's original framing suggested, are still real,
separately-scoped future drills if wanted." Grepping ROADMAP.md and `scripts/`
for "network-partition"/"NetworkPolicy...drill" turned up nothing already tracking
this — a genuine, real, previously-unactioned gap, not manufactured filler.

## What was built

`scripts/dr-network-partition.sh` (`make dr-network-partition`) — a second,
distinct DORA Pillar 3 TLPT-concept drill from `dr-chaos.sh`'s pod-kill, testing a
different self-heal mechanism: it deletes capstone's `allow-capstone-ingress-
from-gateway` NetworkPolicy live (cutting off all Envoy-Gateway-routed ingress,
since ADR-0016's default-deny floor then applies with no allow left), then polls
until ArgoCD's `selfHeal: true` reconciliation
(`gitops/platform/networkpolicy-appset.yaml`'s `syncPolicy.automated`) restores
the object or a 300s budget is exceeded. Where `dr-chaos.sh` exercises
Kubernetes' own ReplicaSet/Rollout controller, this exercises ArgoCD's
GitOps drift-correction path — a genuinely different failure domain and recovery
mechanism, not a duplicate of the existing drill.

Mirrors `dr-chaos.sh`'s exact conventions: sources the same shared libs
(`lib/colors.sh`, `lib/budget-check.sh`, `lib/confirm.sh`,
`lib/dr-results-log.sh`), uses the same `confirm_or_abort` destructive-action
gate, logs to `docs/dr-results-log.md` via `dr_log_result` on both the healed and
not-healed exit paths, and stays out of `make up`/`make ci`/`dr-test`'s own
blocks (on-demand only, per the existing drills' convention).

**Budget reasoning** (verified against this repo's own config, not guessed):
`gitops/platform/networkpolicy-appset.yaml`'s `syncPolicy.automated.selfHeal:
true` is confirmed present, but no tuned reconciliation-interval override exists
anywhere in this repo (`infra/modules/argocd/` or `gitops/platform/argocd*.yaml`)
— ArgoCD's default full-resync timer is ~180s, though selfHeal typically reacts
faster via its resource informer/watch for drift on an already-watched live
object (a separate mechanism from the resync timer, which governs checking git
for new commits). This remote clusterless session has no live ArgoCD instance to
time selfHeal against directly (ADR-0004), so 300s is a deliberately generous
budget rather than a measured one.

## Tests

`tests/dr-network-partition.bats` (16 assertions), mirroring `tests/dr-chaos.bats`'s
structural-only shape (no live cluster needed): script existence/executability,
shared-lib sourcing, the `BUDGET_S` constant, the `dr_log_result` calls on both
exit paths, a recurrence guard that the targeted NetworkPolicy name matches a
real manifest under `gitops/apps/capstone/networkpolicy/` (not an invented/stale
name), a check that the self-heal poll re-queries the object rather than trusting
the delete command's own exit code, and Makefile wiring (`dr-network-partition`
target declared, and NOT invoked from `up`/`ci`/`dr-test`'s own blocks).

## Docs updated

- `Makefile` — new `.PHONY: dr-network-partition` target, mirroring `dr-chaos`'s
  shape.
- `docs/DR.md` — new "Network-partition drill" section (mirrors the existing
  "Chaos / fault-injection drill" section's shape); "Results history log"
  section updated from "four drills" to "five."
- `docs/dora-audit-readiness.md` — Q12's answer/gap text updated to record both
  drills now existing and the narrower remaining gap (Garage-unavailability
  simulation, a different failure domain from either drill here).

`make ci` passes: full local suite green (bats/shellcheck installed this session
via `apt-get`), including all 16 new `tests/dr-network-partition.bats` assertions
and a clean `shellcheck -S warning` pass on the new script (same benign
info-level `SC1091` "not following sourced file" notices `dr-chaos.sh` itself
already carries, confirmed by direct comparison — not a new class of finding).

## Caveats (ADR-0004)

This remote clusterless session authored and structurally verified the script
but has not executed it against a real cluster — same caveat every other
DR-script addition in this repo's history carries. Not yet verified live: (a)
that `kubectl delete networkpolicy` actually blocks the expected traffic in
practice (the ADR-0016 default-deny-floor reasoning is sound but unobserved);
(b) the real wall-clock time ArgoCD's selfHeal takes to restore the object,
which the 300s budget is a generous estimate for, not a measured value.

## PR

https://github.com/tooming/k8s-anywhere/pull/1227
