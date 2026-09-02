# Close DORA audit Q7's named future-candidate gap — add a `VaultSealedDegraded` Grafana alert rule reading `vault_core_unsealed` directly

(CHARTER **Core Values** §"Real observability only" (DORA audit readiness Q7);
planner-fallback gap analysis 2026-09-02, this run's third cycle, reached via
`executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed fully
gated this cycle (same GitLab→Forgejo/capstone-`Deployment` blockers as the two
prior cycles this run) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER all came up empty (no ungroomed intake, no un-RFC'd 🟡 item, digest already
fresh from yesterday, register already current, `make ci` clean with no drift
signal, all 3 open issues already fully labeled). Fresh angle this cycle: continued
mining `docs/dora-audit-readiness.md` (the same document Q15's gap-closure came
from two cycles ago) for another still-open, previously-untouched gap — Q7's own
text explicitly named a concrete future candidate: "a new alert rule reading the
now-scraped `vault_core_unsealed` directly could catch that gap if it proves worth
closing." **No prerequisites — executor may pick up immediately.**)

## What was found

`docs/dora-audit-readiness.md` Q7 ("Is there a defined detection → escalation →
resolution path?") already documented five Grafana Unified Alerting rules (RFC
#1084) and explicitly named a concrete, scoped future candidate in its own "Gap"
line: a rule reading `vault_core_unsealed` (already scraped by
`auto/vault-telemetry-scrape`, surfaced in `lab-vault.json`) directly, as a signal
independent of the existing `VaultPodNotReady` pod-readiness rule. This is real,
previously-untouched gap-analysis output — not manufactured — sitting in a doc this
same run already mined once for Q15.

## Fix

Added a sixth rule, `VaultSealedDegraded`, to
`gitops/platform/observability-grafana.yaml`'s existing `valuesObject.alerting`
block (immediately after `VaultPodNotReady`, same file, same
`groups[0].rules` list — no new Application, no new datasource, no new Alloy scrape
target):

```yaml
- uid: vault-sealed-degraded
  title: VaultSealedDegraded
  condition: B
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: Vault has been sealed for 10+ minutes, read directly from
      vault_core_unsealed (independent of pod-readiness — fires even if
      VaultPodNotReady's readiness-probe signal doesn't).
  data:
    - refId: A
      relativeTimeRange: { from: 600, to: 0 }
      datasourceUid: mimir
      model:
        expr: vault_core_unsealed{job="vault"} == bool 0
        instant: true
        refId: A
    - refId: B
      datasourceUid: __expr__
      model:
        type: threshold
        expression: A
        conditions: [{ evaluator: { type: gt, params: [0] } }]
        refId: B
  noDataState: NoData
  execErrState: Error
```

**Applied the file's own documented stateSet-metric gotcha correctly:** the
`== bool 0` form is required, not a plain `== 0` — the file's own header comment
(cited directly, not re-derived) explains that a plain `== 0` filter on a matched
series returns that series' own value (0), so a `gt 0` threshold on it can never
fire; `bool` forces the comparison to emit `1` on a true match instead, which the
threshold expression can actually see.

**Honest framing, not overclaimed (ADR-0004):** this rule is a direct, independent
seal-state signal alongside `VaultPodNotReady`'s pod-readiness one — it does **not**
assert that `VaultPodNotReady` has a proven blind spot. Whether Vault's own
readiness probe reflects seal state on this lab's specific chart configuration is
something this remote clusterless session cannot verify live either way, so the
docs updated here (ROADMAP, `docs/dora-audit-readiness.md`, `docs/dependency-tree.md`,
the rule's own `summary` annotation, and the bats test description) were all
deliberately worded to describe this as "an additional, independent signal", never
as "closing a proven gap in the other rule" — an earlier draft of this change did
overclaim the specific mechanism (sealing "doesn't fail the readiness probe") before
this same self-review pass caught and corrected it.

Updated `tests/observability-alerting.bats`: added a presence/expr assertion for
the new rule, and bumped the existing "all N rules" `for`-duration and
`datasourceUid: mimir` count assertions from five to six. Updated
`docs/dependency-tree.md`'s Grafana-alerting dependency row to list the new rule.
Updated `docs/dora-audit-readiness.md`'s Q7 answer and gap text to describe six
rules and cite the new one, narrowing (not fabricating closure of) the section's
remaining real gaps (escalation stays a permanent non-goal for this solo-operator
lab; the CI-health MTTR metric still only covers CI, not a live-cluster incident).

`make ci` / local bats (`tests/observability-alerting.bats`,
`tests/observability.bats`, `tests/dora-audit-readiness.bats`,
`tests/dependency-register.bats`, `markdown-links-check`, `o5-dashboard-coverage-check`,
`lab-ui-check`): green.

**ADR-0004 caveat:** this remote clusterless session cannot verify the new rule
actually fires on a live Grafana instance against a real sealed Vault — the YAML
shape and PromQL expression are verified structurally (matches the file's own
established, already-working rule pattern exactly) and via the `bool`-comparison
gotcha already proven correct by the existing `VaultPodNotReady`/`DeploymentReplicasUnavailable`
rules in this same file, not by observing this specific rule fire live.

## PR

https://github.com/tooming/k8s-anywhere/pull/1377
