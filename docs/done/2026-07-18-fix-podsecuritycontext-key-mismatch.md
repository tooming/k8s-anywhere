# Fix `podSecurityContext` key-path mismatches across the observability stack

Bugfix discovered during this run's upgrade-drafter chart-compatibility audits (PRs #490,
#491, #492 — kube-state-metrics, node-exporter, and alloy chart bumps). CHARTER **Objective
O2** hardening / ADR-0017 correctness — no new architectural decision, this corrects
enforcement of an already-decided posture.

## The bug

Four ArgoCD `Application`s in `gitops/platform/` set a `podSecurityContext` key in their
Helm `valuesObject` intending to configure the pod-level `securityContext` (runAsNonRoot,
runAsUser/runAsGroup, seccompProfile — the ADR-0017 restricted-profile fields). For each
of these charts, `podSecurityContext` does not exist anywhere in the chart's actual values
schema — verified directly against each pinned chart's `values.yaml` and template source:

| Application | Wrong key (no-op) | Correct key |
|---|---|---|
| `observability-ksm.yaml` | `podSecurityContext` | `securityContext` (chart default already matched our intent — functionally benign, but the override itself did nothing) |
| `observability-node-exporter.yaml` | `podSecurityContext` | `securityContext` (chart default lacks `seccompProfile` — this field was likely unenforced) |
| `observability-grafana.yaml` | `podSecurityContext` | `securityContext` (chart default matched `runAsNonRoot`/`runAsUser`/`runAsGroup`/`fsGroup` — `seccompProfile` was likely unenforced at pod level) |
| `observability-alloy.yaml` | `controller.podSecurityContext` | `global.podSecurityContext` (wrong nesting, not just wrong name — chart has no default here at all, so this was a real gap) |

Two Applications using `podSecurityContext` were independently verified as already correct
and are untouched: `external-secrets.yaml` (documented in its own in-file comment) and
`kro.yaml` (`deployment.podSecurityContext` is the chart's real key). `ack-s3.yaml`'s
`podSecurityContext`/`securityContext` overrides are a different, unrelated finding
(already documented transparently in PR #489's body): that chart hardcodes its pod/
container securityContext directly in the template, so **no** values-based key would work
there — not touched in this fix.

## Why the existing tests didn't catch it

Every affected test in `tests/securitycontext-observability.bats` was a bare
`grep -q 'value' "$FILE"` checking that a field *value* (e.g. `runAsNonRoot: true`)
appeared *somewhere* in the file — never that it was nested under the correct parent key.
For Grafana specifically, this was worse than a false negative: the file's
`extraInitContainers` block sets its own inline `securityContext` (a real, correctly-keyed
per-container override for the CA-bundle init container) containing the same field names,
so the old tests would have kept passing even if the top-level block were deleted entirely.

## The fix

1. Renamed/moved each `podSecurityContext` override to the chart's real key path, keeping
   the exact same intended values (adding `securityContext.enabled: true` explicitly for
   kube-state-metrics, whose chart gates the whole block behind that flag).
2. Added an in-file comment at each site explaining the chart's real key and citing the
   verification source (values.yaml + template).
3. **Recurrence guard**: converted the bare-grep tests for these four components' pod-level
   fields into path-aware `yqs()` assertions (this repo's existing yq-variant-robust bats
   helper, `tests/lib/yq.bash`) querying the exact `spec.source.helm.valuesObject.<path>`
   each field must live at, plus an explicit "does NOT use the dead key" negative assertion
   for each fixed Application. Verified the guard is real (not tautological) by temporarily
   reverting the kube-state-metrics fix locally and confirming the corresponding tests fail
   (4 failures), then restoring and confirming all pass again.

## Verification

Checked each chart's actual pinned-version `values.yaml` and the relevant deployment/
daemonset/pod template directly (not just documentation) via `raw.githubusercontent.com`
fetches of the exact pinned tag, for all four fixed Applications plus the two Applications
confirmed already-correct. `bats tests/securitycontext-observability.bats`: 52/52 pass.
`make ci`: green (same pre-existing local-only `yq`/`jq` tag-filter failures as `main`,
unrelated to these files).

## What this does NOT claim

Per ADR-0004: this is a clusterless environment, so whether the corrected `securityContext`
actually takes effect cleanly on a live cluster (e.g., Alloy or Grafana starting under the
now-enforced `seccompProfile`) is not verifiable here. All four components already ran
under PSA `restricted` namespaces before this fix — RuntimeDefault seccomp is the
kubelet/container-runtime default behavior for `restricted`-compliant workloads in most
cases even without an explicit profile, so this fix closes a **configuration-intent gap**
(the repo's own config now actually does what its comments already claimed), not
necessarily a previously-exploitable live gap. Rollback: revert this commit — every touched
key reverts atomically with it, ArgoCD self-heals within its sync interval.

## PR

https://github.com/tooming/k8s-anywhere/pull/493
