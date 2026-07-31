# Add missing istio-system-extras row to dependency-tree.md's apply-order table

While auditing sync-waves for the previous `istio-system-extras.yaml` comment fix
(PR #948), found that `docs/dependency-tree.md`'s apply-order table lists a dedicated
"— | X-extras *(auto-synced, wave 0)*" row for every other always-on namespace-floor
shim paired with an on-demand heavy component — `tidb-admin-extras`, `harbor-extras`,
`longhorn-extras` — but never for `istio-system-extras`, despite the `tidb-admin-extras`
row's own text explicitly citing "the harbor-extras/longhorn-extras/istio-system-extras
pattern" as a three-member set. `istio-system-extras` was previously mentioned only in
this doc's per-namespace prose section (`istio-system namespace PSS privileged +
NetworkPolicy`), never in the actual apply-order table alongside `istio-base`/
`istio-cni`/`istiod`/`ztunnel`.

Verified directly: `gitops/platform/istio-system-extras.yaml` runs at sync-wave 0 with
`syncPolicy.automated` set, matching the other three precedents exactly.

## Fix

Added the missing row directly above `istio-base`'s row, following the established
`X` → `X-extras` ordering convention: "— | istio-system-extras *(auto-synced, wave 0)* |
Pre-creates the `istio-system` namespace with PSA `privileged` labels ...".

Extended `tests/istio-system-extras.bats` (new PR #948 test file) with one more
assertion: the apply-order table contains the exact `istio-system-extras *(auto-synced,
wave 0)*` string — a recurrence guard so a future edit that drops this row again fails
CI.

Doc + test-only change — no manifest or behavior change.

**Note for a future cycle:** while auditing this, also noticed `argocd-extras`,
`kargo-extras`, and `trivy-extras` don't appear anywhere in the apply-order table
either (inline in wave 0's list, or as their own "—" row) — unlike this fix's
`istio-system-extras` case, their correct table placement isn't as clear-cut (e.g.
`trivy-extras`' heavy sibling `trivy-operator` is itself always-on, unlike harbor/
longhorn/tidb-admin/istio-system's on-demand heavy siblings, so it may belong inline
in wave 0's row rather than as a dedicated "—" row). Left uninvestigated this cycle to
avoid an under-verified fix; flagging for a future doc-drift pass.

**Blast radius on a live cluster:** none — documentation and test-only.

`make ci` passes.

## PR

(filled in after PR creation)
