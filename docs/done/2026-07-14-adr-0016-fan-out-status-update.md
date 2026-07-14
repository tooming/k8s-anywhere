# ADR-0016 — update the stale pilot-stage tables to reflect fan-out completion

Continuing ROADMAP rule #9's coverage/hardening sweep: ADR-0016 (default-deny
NetworkPolicy) had never been substantively edited since it was authored as the
`data`-namespace pilot doc, even though the fan-out it describes as future work
completed months ago. Per ADR-0004 ("never fabricate content presented as real
state"), a binding ADR describing a stale, superseded state as current is exactly
the kind of drift that rule applies to.

## What was stale

- **"Staged rollout" table** (§4) still listed only the pilot (`data`) plus a
  10-namespace "Fan-out" list and a 3-namespace "On-demand" list with "policy lands
  **with** the bring-up PR" — but `gitops/platform/networkpolicy-appset.yaml` (a
  list-generator `ApplicationSet` that didn't exist when this ADR was written) now
  auto-syncs the default-deny floor for on-demand namespaces (`istio-system`,
  `longhorn-system`, `artifactory`, `harbor`, `inkless`) *ahead of* their bring-up,
  not "with" it — verified directly: every appset-generated Application carries
  `syncPolicy.automated: {prune: true, selfHeal: true}`.
- **"Scope & exceptions"** still listed 11 in-scope namespaces. The real count is 27,
  confirmed by cross-referencing `find gitops -type d -name networkpolicy`,
  `gitops/platform/networkpolicy-appset.yaml`'s list-generator (20 namespaces), and the
  7 standalone `<ns>-networkpolicy` Applications (`kyverno`, `trivy-system`,
  `argo-rollouts`, `envoy-gateway-system`, `velero`, `kargo`, `kargo-project`) that
  predate or sit outside the appset.
- **"Files this work touches"** only listed the `data`-namespace pilot files — missing
  the appset (the primary delivery mechanism today) and the 7 standalone Applications
  entirely.

## Fix

Rewrote the Status line, the "Staged rollout" table, "Scope & exceptions" (namespace
list + carve-outs table), and "Files this work touches" to reflect current reality —
and, to avoid re-staling immediately, pointed the namespace enumeration at
`docs/dependency-tree.md` (confirmed continuously maintained) as the live source of
truth, with this ADR kept as the *pattern* description rather than a duplicate list
that needs updating on every namespace add.

No code changes; no bats reference this ADR's prose, so no test changes needed.
`make ci` passes (same 7 pre-existing environment-only failures as prior PRs this
session).

## PR

(this session's branch)
