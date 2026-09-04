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

## Follow-up fixup (same PR)

A second review pass (a fresh Explore-agent sweep, cross-checked manually) caught two
more errors, one self-introduced by the edit above:

- The namespace list this PR added named `kargo-project` as one of the 27 — but
  `kargo-project` is only the ArgoCD Application-name/git-path family
  (`gitops/platform/kargo-project.yaml`, `kargo-project-networkpolicy.yaml`,
  `gitops/kargo-project/`); the actual Kubernetes namespace it manages is
  `capstone-pipeline` (verified: `gitops/kargo-project/namespace.yaml`'s
  `metadata.name`, the kustomize overlay's `namespace:` field, the Application's
  `destination.namespace`, and `docs/dependency-tree.md`'s existing label — all say
  `capstone-pipeline`). Swapped the entry; the two references to `kargo-project` that
  correctly meant the Application-name family (the "Fan-out" row and "Files this work
  touches") were left as-is.
- `docs/decisions/adr-0023-kargo-promotion-pipeline.md`'s own "NetworkPolicy + PSS" and
  "Files this work touches" sections only documented the `kargo` namespace overlay,
  even though its own ADR-0016 cross-reference row already promised coverage for both
  `kargo` *and* `capstone-pipeline` — the `capstone-pipeline` NetworkPolicy overlay
  (`gitops/kargo-project/networkpolicy/`), its delivery Application
  (`gitops/platform/kargo-project-networkpolicy.yaml`), the namespace's PSA labels
  (`gitops/kargo-project/namespace.yaml`), and its test file
  (`tests/networkpolicy-capstone-pipeline.bats`, 15 tests) were real, shipped, and
  simply never written up. Added the missing paragraph + three table rows.

## PR

https://github.com/tooming/k8s-anywhere/pull/404
