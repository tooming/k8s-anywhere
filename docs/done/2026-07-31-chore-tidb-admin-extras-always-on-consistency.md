# Bring tidb-admin-extras in line with the harbor/longhorn/istio-system-extras always-on-namespace-floor pattern

CHARTER.md's "Heavy / on-demand" bullet groups TiDB, Harbor, Istio, and Longhorn as
equivalent on-demand components. For three of the four, the repo has converged on a
deliberate pattern: a companion `*-extras` Application that pre-creates the heavy
component's namespace (with its PSA labels) and is **auto-synced** at sync-wave 0 —
`harbor-extras.yaml` (PR #306), `longhorn-extras.yaml` (PR #284), and
`istio-system-extras.yaml` (PR #285) all carry an `ALWAYS-ON` comment explaining the
same rationale: an empty namespace with PSA labels is cheap and harmless while the
heavy component itself stays manual-sync, and having the floor present before
`make X-up` runs is real safety, not SPOF theatre.

`gitops/platform/tidb-admin-extras.yaml` (created earlier, before this pattern was
established) never got the memo — it had no `automated:` block and its own comment
actively told future editors not to add one ("TiDB lives outside the always-on 12 GB
stack"), reasoning that the later harbor/longhorn/istio-system-extras PRs explicitly
moved past: the heavy component (TiDB itself) staying on-demand doesn't mean its
namespace-floor shim has to.

Verified directly: `gitops/tidb-admin/` contains only a `namespace.yaml` (PSA
`baseline` labels) — structurally identical in purpose to
`gitops/harbor/namespace.yaml`/`gitops/longhorn/namespace.yaml`/
`gitops/istio-system/namespace.yaml`. `gitops/bootstrap/root-app.yaml` already
recursively watches all of `gitops/platform/`, so `tidb-admin-extras.yaml` is already
applied — enabling `automated:` only changes its own sync policy, no other file needs
to register it. No test previously covered `tidb-admin-extras.yaml` at all.

## Fix

Added the `argocd.argoproj.io/sync-wave: "0"` annotation and `syncPolicy.automated:
{prune: true, selfHeal: true}` block to `tidb-admin-extras.yaml`, rewriting its
comment to mirror the established rationale. The `tidb-operator` Application itself
(the actual heavy component) is untouched — still on-demand, manual-sync only.

New `tests/tidb-admin-extras.bats` (5 assertions: existence, sync-wave, auto-sync,
source path, and a regression guard confirming `tidb-operator.yaml` itself stays
non-auto-synced — using a line-start-anchored `automated:` grep, since a naive
substring grep would false-positive on that file's own "no automated: block"
comment prose).

Also fixed two related `docs/dependency-tree.md` rows found in the same pass:
`tidb-admin-extras`'s row still said "(on-demand)" (now corrected to match this fix),
and `longhorn-extras`'s row *already* mislabeled itself "(on-demand)" despite the
manifest already being auto-synced since PR #284 — that mislabel predates this PR and
is fixed alongside it since both rows describe the exact same "extras" pattern this
PR touches.

**Blast radius on a live cluster:** adds one `Namespace` resource + PSA labels to
auto-sync (`tidb-admin`, PSA `baseline`) — no workload, no pods, matching the
already-accepted harbor/longhorn/istio-system-extras precedent exactly. Rollback:
revert the `automated:` block; ArgoCD stops auto-reconciling this Application (the
namespace itself is not pruned by reverting sync policy alone).

`make ci` passes (2350 assertions, 0 failures).

## PR

https://github.com/tooming/k8s-anywhere/pull/946
