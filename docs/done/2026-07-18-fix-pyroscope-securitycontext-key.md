# Fix `containerSecurityContext` key mismatch — Pyroscope

Janitor sweep, found while checking for lingering instances of the same bug class PR
#493 fixed (`podSecurityContext` key-path mismatches across the observability stack).
CHARTER **Objective O2** hardening / ADR-0017 correctness — no new architectural
decision, this corrects enforcement of an already-decided posture.

## The bug

`gitops/platform/observability-pyroscope.yaml` set a `pyroscope.containerSecurityContext`
key in its Helm `valuesObject`, intending to configure the container-level
`securityContext` (`allowPrivilegeEscalation: false`, `privileged: false`,
`readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`). `containerSecurityContext`
does not exist anywhere in the pinned `pyroscope-2.0.3` chart's values schema — verified
directly against the chart's actual `values.yaml` (no such key, at any nesting level)
and its `templates/deployments-statefulsets.yaml` (the container-level `securityContext:`
block explicitly renders from `.Values.pyroscope.securityContext`, not
`containerSecurityContext`). This is the same class of bug PR #493 fixed for
`observability-ksm.yaml`, `observability-node-exporter.yaml`,
`observability-grafana.yaml`, and `observability-alloy.yaml` — a fifth instance in the
same observability stack that PR #493's scope (four named Applications) didn't cover.

Practical impact: Pyroscope's container ran with the chart's own default
`securityContext: {}` (empty) the entire time — `allowPrivilegeEscalation`,
`privileged`, `readOnlyRootFilesystem`, and `capabilities.drop` were never actually
applied at the container level, despite the ROADMAP's "readOnlyRootFilesystem tighten
— Pyroscope" item (checked off 2026-07-1x) claiming this was verified and flipped. The
pod-level `podSecurityContext` key was already correct (verified against the chart:
`.Values.pyroscope.podSecurityContext` does render the pod-level block) and is
untouched.

## Why the existing tests didn't catch it

Every affected assertion in `tests/securitycontext-observability.bats` was a bare
`grep -q 'value' "$FILE"` checking that a field *value* (e.g.
`readOnlyRootFilesystem: true`) appeared *somewhere* in the file — never that it was
nested under the correct parent key. The exact same blind spot PR #493 documented for
Grafana/KSM/node-exporter/Alloy.

## The fix

1. Renamed `pyroscope.containerSecurityContext` → `pyroscope.securityContext` (the
   chart's real key), keeping the exact same intended values.
2. Added an in-file comment citing the verification source (values.yaml + template) and
   noting this is the same bug class as PR #493, missed by that PR's scope.
3. **Recurrence guard**: converted the bare-grep tests for Pyroscope's container-level
   fields into path-aware `yqs()` assertions (mirroring PR #493's exact pattern) querying
   `spec.source.helm.valuesObject.pyroscope.securityContext.*`, plus an explicit "does
   NOT use the dead `containerSecurityContext` key" negative assertion. Verified the
   guard is real (not tautological) by temporarily reverting the fix locally and
   confirming the four new/changed assertions fail, then restoring and confirming all
   pass again.

## Verification

Checked the pinned `pyroscope-2.0.3` chart's actual `values.yaml` and
`templates/deployments-statefulsets.yaml` directly (not just documentation) via a
direct git fetch of the exact pinned tag from `grafana/pyroscope` (the chart lives in
the app's own repo, not `grafana/helm-charts` — `grafana.github.io/helm-charts` is
just the publish index; matches the pattern already documented in this repo's
"observability readOnlyRootFilesystem tighten — Pyroscope" done entry).
`bats tests/securitycontext-observability.bats`: 53/53 pass. `make ci`: green (same
pre-existing sandbox-only failures unrelated to this change, confirmed via `git stash`
against unmodified `main`).

## What this does NOT claim

Per ADR-0004: this is a clusterless environment, so whether the corrected
`securityContext` actually takes effect cleanly on a live cluster (Pyroscope starting
under the now-enforced `readOnlyRootFilesystem: true` + dropped capabilities) is not
verifiable here. Pyroscope already ran under the `observability` namespace's PSA
`restricted` label before this fix, so the built-in Kubernetes PSA admission control
was already enforcing pod-level restricted requirements regardless of this chart-level
values gap; this fix closes a **configuration-intent gap** at the container level (the
repo's own config now actually does what it already claimed), consistent with how PR
#493 scoped its own claim. Rollback: revert this commit — the key reverts atomically,
ArgoCD self-heals within its sync interval.

## PR

https://github.com/tooming/k8s-anywhere/pull/507
