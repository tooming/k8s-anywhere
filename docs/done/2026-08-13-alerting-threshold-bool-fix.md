# Fix two Grafana Unified Alerting rules that can never fire — threshold-vs-stateSet-metric bug (RFC #1084 follow-up)

(CHARTER **Core Values** §"operational-resilience discipline" + §"Real observability
only" (ADR-0004 — a rule that structurally can never fire is a worse-than-nothing
false sense of coverage); planner-fallback gap analysis 2026-08-13, reached via
`executor.prompt.md` STEP 6b, PLANNER role — Now/next's remaining items are all
still gated (the three standing GitLab→Forgejo migration items on live-cluster
verification, `auto/cosign-enforce-flip` and `auto/capstone-deployment-removal` on
unconfirmed maintainer-confirmation issues #631/#633, re-checked this cycle,
unchanged) and this run's own sweep found no un-RFC'd 🟡 item and no ungroomed
issue to promote. **No prerequisites — executor may pick up immediately.**) Found
while re-reading `docs/dora-audit-readiness.md` Q7 for further gap-analysis
angles, then verifying the alerting rules it cites are actually correct (ADR-0004
discipline — don't just trust a doc's prior "closed" claim without re-checking the
underlying mechanism). Verified directly against Grafana's own Unified Alerting
semantics (not assumed): a `type: threshold` expression (refId B) applies its
`evaluator` (here, always `gt 0`) **directly to refId A's own returned numeric
value** — it does not coerce "the query matched a series" into a boolean 1.
`kube-state-metrics` publishes several metrics as a *stateSet* — one series **per
enum value** every scrape, each literally 0 or 1 (confirmed against this repo's
own dashboard usage pattern, e.g. every `kube_pod_status_phase{phase="Running"}`
stat panel across `grafana/dashboards/*.json` assumes exactly this "1 in the
matching case" shape). Two of the five existing rules got this backwards:

- `VaultPodNotReady`'s `expr: kube_pod_status_ready{namespace="vault",
  pod=~"vault-[0-9]+", condition="true"} == 0` filters to the `condition="true"`
  series and keeps it only when its value **is** 0 (pod not Ready) — so the
  returned value is always exactly 0 in the firing case, and downstream `gt 0`
  on 0 is always false. **This rule — the one `auto/vault-pod-readiness-alert`
  (2026-08-11) added specifically to close the real "Vault sealed 4+ days,
  nothing surfaced" incident gap named in Q7 — could never have fired, in any
  state, since the day it merged.**
- `DeploymentReplicasUnavailable`'s `expr:
  kube_deployment_status_replicas_available < kube_deployment_spec_replicas`
  returns the *available* replica count wherever the comparison holds — so the
  worst case (`available == 0`, total outage) evaluates `0 gt 0` = false and
  never fires; only a *partial* shortfall (available > 0 but < desired) was ever
  caught.

The other three rules (`ArgoCDAppUnhealthy`, `ArgoCDAppOutOfSync`,
`PVCStuckPendingOrLost`) don't have this bug: `argocd_app_info` is a plain "info"
metric always valued 1 (not a stateSet), and `PVCStuckPendingOrLost` filters to
`== 1` (the stateSet's *true* value), so both already return a nonzero value in
the firing case.

## Fix

`VaultPodNotReady`'s expr now uses PromQL's `bool` modifier —
`kube_pod_status_ready{namespace="vault", pod=~"vault-[0-9]+", condition="true"}
== bool 0` — which always evaluates to 1/0 for the matched series regardless of
the raw metric's own value, correctly pairing with the downstream `gt 0`.
`DeploymentReplicasUnavailable`'s expr now computes the deficit directly —
`kube_deployment_spec_replicas - kube_deployment_status_replicas_available` —
whose value is exactly what "greater than zero" should mean, correctly firing at
any shortfall including total outage. Added a `GOTCHA` comment block directly
above `alerting.rules.yaml` in `gitops/platform/observability-grafana.yaml`
documenting this trap (threshold-evaluates-the-raw-value + stateSet-metrics'
per-enum-value shape) so a future rule author doesn't reintroduce it — the
mechanical-recurrence-guard CLAUDE.md's bugfix rule calls for, since a live
PromQL-evaluation test isn't possible from this clusterless session (ADR-0004).

Extended `tests/observability-alerting.bats`: updated the two rules' existing
expr assertions to the fixed strings; added two explicit regression-guard
assertions asserting the old broken expr strings are **absent** (mirrors this
repo's existing "does NOT use the dead X" pattern, e.g.
`tests/kargo.bats`/`tests/kyverno.bats`); added an assertion the new `GOTCHA`
comment is present. `for:`/`datasourceUid: mimir` count assertions are unchanged
(edits touched only the `expr:` lines, not rule count/shape). `make ci` passes.

PR body documents the ADR-0004 caveat that this remote clusterless session
verified the fix via PromQL/Grafana-Alerting semantics reasoning, not a live
firing test, and the rollback path (revert the two `expr:` lines; ArgoCD syncs
the revert within 30s, same as any other `alerting.yaml` edit — reverting only
restores the *prior*, already-broken-in-production behavior, so there is no new
risk from rolling back).

## PR

https://github.com/tooming/k8s-anywhere/pull/1187
