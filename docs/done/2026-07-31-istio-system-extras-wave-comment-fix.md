# Fix stale sync-wave numbers in istio-system-extras.yaml's header comment

`gitops/platform/istio-system-extras.yaml`'s header comment claimed Istio components
schedule at "istio-base wave 1, istiod wave 2, istio-cni wave 2, ztunnel wave 2" — but
the actual on-disk `argocd.argoproj.io/sync-wave` annotations, verified directly, are:

- `gitops/platform/istio-base.yaml` → wave 1 (comment was correct)
- `gitops/platform/istio-cni.yaml` → wave 2 (comment was correct)
- `gitops/platform/istiod.yaml` → wave 3 (comment said 2 — wrong)
- `gitops/platform/ztunnel.yaml` → wave 4 (comment said 2 — wrong)

The components were staggered into separate incremental waves at some point after this
comment was originally written, and the comment was never updated — classic
comment/code drift, caught by a systematic sync-wave-vs-doc cross-check rather than a
spot-check.

## Fix

Corrected the comment to read "istio-base wave 1, istio-cni wave 2, istiod wave 3,
ztunnel wave 4" (also reordered ascending to match the real wave sequence). Comment-only
change — no manifest or behavior change.

New `tests/istio-system-extras.bats` (8 assertions): existence/sync-wave-0/auto-sync
for `istio-system-extras.yaml` itself, plus a recurrence guard asserting each of
`istio-base`/`istio-cni`/`istiod`/`ztunnel`'s actual sync-wave annotation AND the
header comment's stated wave numbers both hold — so if any of the four Applications'
wave annotation is bumped again in the future without updating this comment, CI catches
it.

**Blast radius on a live cluster:** none — comment-only change, no annotation values
changed.

`make ci` passes.

## PR

https://github.com/tooming/k8s-anywhere/pull/948
