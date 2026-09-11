# Write a fault-injection drill against a currently-live always-on component

Found live 2026-09-11 (planner gap analysis, cycle 4 of this run, re-reading
`docs/dora-audit-readiness.md` against the current 4-namespace repo state): Q12
("Is there an adversarial/penetration-style test (DORA's TLPT concept)?") names a
real, still-open gap verbatim — the three fault-injection drills this lab used to
run (`dr-chaos`, `dr-network-partition`, `dr-garage-failure`) each targeted a
component removed entirely 2026-09-07 (capstone, Garage) and were deleted with no
replacement written against any currently-live component, and Q13 (test
results/remediation tracking) independently confirms no such mechanism exists any
more either. Q12's own text names the concrete, buildable instance: "kill the
single-replica ArgoCD pod and assert Kubernetes' own self-heal" — this directly
serves CHARTER's Goals ("operational-resilience discipline... mapped onto concrete
GitOps practice") and is entirely clusterless-*writable* even though it only *runs*
against a live cluster (same shape as the existing `scripts/dr-test.sh`/
`dr-verify.sh`/`dr-destroy.sh`, none of which run in CI either — `make ci` only
lints them and exercises their non-destructive guard paths, per
`tests/dr-guards.bats`'s existing pattern).

**Scope:** add `scripts/dr-chaos-argocd.sh` (kill the
`app.kubernetes.io/name=argocd-application-controller` pod — the label this repo's
own `gitops/argocd/networkpolicy/*.yaml` already uses for its sibling components —
via the same `confirm_or_abort`/`DR_ASSUME_YES` type-to-confirm gate as
`dr-destroy.sh`/`dr-test.sh`, then poll for a new Ready pod (a different UID) and
for every ArgoCD `Application` to return to Synced+Healthy, mirroring
`dr-verify.sh`'s own `p_argo` predicate); a `make dr-chaos-argocd` target under the
Makefile's "Disaster recovery" section; guard-only bats coverage in
`tests/dr-guards.bats` (unknown-usage/no-confirmation-refusal paths only, same
non-destructive pattern already used for `dr-test.sh`/`dr-destroy.sh` — never
actually invoking a live cluster from `make ci`); a `docs/DR.md` section
documenting it; a `README.md` update (the Disaster Recovery section previously
stated "There is no automated backup/restore, fault-injection, or blue/green drill
left" — this closes the fault-injection half of that claim, so the claim and the
table needed updating together, not left contradicting the new script); and an
honest update to `docs/dora-audit-readiness.md`'s Q12 **Answer**/**Gap** fields
reflecting that one concrete fault-injection drill now exists against a live
always-on component — explicitly NOT an adversarial/penetration-style TLPT test,
and NOT a claim of regulatory compliance (CHARTER's own Goals section already
states this lab's DORA framing is "explicitly as an educational lens, never a
regulatory compliance claim this lab cannot honestly make" — Q12's updated answer
preserves that framing, not overclaiming).

## What was built

- `scripts/dr-chaos-argocd.sh` — deletes the live `argocd-application-controller`
  pod (behind the standard `confirm_or_abort`/`DR_ASSUME_YES` type-to-confirm gate
  this repo already uses for `dr-test.sh`/`dr-destroy.sh`), then polls (up to
  `DR_T_POD`, default 120s) for a new Ready pod with a different UID, then polls
  (up to `DR_T_ARGO`, default 300s) for every ArgoCD `Application` to return to
  `Synced`+`Healthy` — the identical predicate shape `dr-verify.sh`'s own `p_argo`
  check already uses. Requires a live cluster; verified locally (no cluster
  available in this clusterless session) that both guard paths behave correctly:
  refuses non-interactively without `DR_ASSUME_YES=1`, and with it set, fails
  gracefully with a clear "no live pod found" message rather than crashing when no
  cluster is reachable — never touches anything destructive in either path.
- `make dr-chaos-argocd` Makefile target.
- Two new guard-only bats tests in `tests/dr-guards.bats`, matching its existing
  non-destructive pattern for `dr-test.sh`/`dr-destroy.sh`.
- `docs/DR.md`: a new "`make dr-chaos-argocd` — fault-injection drill" section, and
  an update to the "Honest scope" paragraph (no longer claims zero fault-injection
  drills exist).
- `README.md`: updated the Disaster Recovery section's claim and added a table row
  for the new command.
- `docs/dora-audit-readiness.md`: Q12's Answer/Gap fields updated to reflect the
  narrowed (not closed) gap — one drill against one component, not a TLPT/
  adversarial test, not a compliance claim.

`make ci`: green.

## PR

auto/dr-chaos-argocd
