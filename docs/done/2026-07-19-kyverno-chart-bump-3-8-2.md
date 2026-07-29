# Bump Kyverno chart `3.3.9` → `3.8.2`

(Upgrade-drafter fallback role, autonomous run, 2026-07-19. CHARTER **Core Values**
§"Everything as code" + general hardening.)

No newer patch existed within the `3.3.x`/`3.4.x`/`3.5.x`/`3.6.x`/`3.7.x` lines —
`3.8.2` is the newest **stable** chart release, verified against the chart repo's own
`gh-pages` index (`https://kyverno.github.io/kyverno/`, backed by
`raw.githubusercontent.com/kyverno/kyverno/gh-pages/index.yaml`), skipping the
`3.8.2-rc.2` pre-release candidate that preceded it. This is a same-major (chart major
stays `3`), non-pre-release bump — appVersion moves `v1.13.6` → `v1.18.2`.

Verified before landing (mirrors the 2026-07-18 `3.3.4 -> 3.3.9` bump's own
diligence, scaled up for the larger jump):

- `values.yaml` at tag `kyverno-chart-3.8.2`: all four controllers
  (`admissionController`, `backgroundController`, `cleanupController`,
  `reportsController`) still expose the same `replicas` + `resources.limits` shape
  this Application's `valuesObject` sets — no schema break.
- `admissionController`'s `containerSecurityContext` defaults are unchanged and still
  Pod Security Standard **restricted**-compatible (`runAsNonRoot: true`,
  `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`,
  `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault`) — no regression
  against RFC #483's PSA-restricted flip (ADR-0017/ADR-0019).
- `gitops/kyverno/policies/*.yaml` (the separate `kyverno-policies` Application) all
  use the stable, unaffected `kyverno.io/v1` `ClusterPolicy` API — no policy-side
  change needed for this bump.
- Chart's `artifacthub.io/changes` annotation for `3.8.2` lists three items: a
  `spec.template.metadata` nil-pointer fix, removal of an unused `policyexceptions`
  delete permission from the admission controller's RBAC, and two new controller
  flags (`--generateValidatingAdmissionPolicy`, `--validatingAdmissionPolicyReports`)
  defaulting on — both are opt-in *features*, not behavior changes to anything this
  lab's `ClusterPolicy` set already uses.

Bumped `gitops/platform/kyverno.yaml`'s `targetRevision` from `3.3.9` to `3.8.2`,
added an inline comment documenting the verification above. Extended
`tests/kyverno.bats`: updated the pin assertion to `3.8.2`, added a new recurrence
guard asserting the superseded `3.3.9` pin is absent (alongside the existing
`3.3.4` guard).

`make ci` passes locally (bats installed this session for higher-confidence local
verification) — confirmed via `git stash` against unmodified `main` that this change
introduces **zero new failures**: the exact same 13 pre-existing, unrelated failures
(caused by this sandbox's python/jq-based `yq` rather than mikefarah's `yq`) appear
identically with and without this diff. All 54 `tests/kyverno.bats` assertions pass.

**ADR-0004 caveat:** this remote clusterless session cannot verify the Kyverno
controllers actually roll out cleanly on a live cluster with this chart version.
**Rollback path:** revert `targetRevision` back to `3.3.9` — ArgoCD self-heals; all
four controllers are Deployments so a revert re-rolls the same way the bump did.

## PR

[#556](https://github.com/tooming/k8s-anywhere/pull/556)
