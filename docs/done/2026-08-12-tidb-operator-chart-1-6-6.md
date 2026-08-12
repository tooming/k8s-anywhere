# Bump TiDB Operator chart `1.6.5` → `1.6.6` (RBAC least-privilege hardening)

(CHARTER **Core Values** §"Everything as code" + general hardening; JANITOR-fallback
currency sweep 2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role,
after the Now/next lane was re-confirmed fully gated (six items, unchanged, still
blocked on unconfirmed standing issues #631/#633 — re-checked directly, both still
open, no new comment since 2026-08-11) and the dashboard metric-accuracy audit
(this run's prior two cycles, PR #1157/#1158) was set aside in favor of a different
angle per STEP 8's "widen the lens" guidance: a chart-currency sweep across every
`gitops/platform/*.yaml` `targetRevision` pin. No prerequisites — executor may pick
up immediately.)

## What was found

Swept every pinned chart's `targetRevision` (`ack-s3`, `argo-rollouts`,
`cert-manager`, `cilium`, `envoy-gateway`, `external-secrets`, `harbor`,
`istio-base`/`istio-cni`/`istiod`, `kargo`, `keda`, `kiali`, `kro`, `kyverno`,
`longhorn`, `observability-alloy`/`grafana`/`ksm`/`node-exporter`/`pyroscope`,
`tidb-operator`, `trivy-operator`, `vault`, `velero`, `ztunnel`) against each
project's real tag list via `git ls-remote --tags`. Every pin was already current
**except TiDB Operator**: pinned `1.6.5`, real newest `1.6.x` tag is `1.6.6`.

ADR-0031 (adopted 2026-08-05) holds `tidb-operator` at the `1.6.x` line — its own
"Consequences" section carves this exact case out explicitly: "Future currency
sweeps that find a newer `1.6.x` patch release (not a `2.x` major) remain in scope
for a routine executor bump, same as any other component — this ADR only governs
the major-line question." `1.6.6` is a same-line patch, not the `v2.0.x` major
rewrite the hold targets — in scope.

## Verification

Full clone diff (`git diff v1.6.5 v1.6.6 -- charts/tidb-operator/`, the real
Helm chart source at `github.com/pingcap/tidb-operator`) — a real, security-relevant
change, not a routine no-op bump: every ClusterRole/Role this chart renders
(`controller-manager-rbac.yaml`, `advanced-statefulset-rbac.yaml`,
`admission-webhook-rbac.yaml`) replaces a wildcard `resources: ["*"]` /
`verbs: ["*"]` grant with an explicit least-privilege list — e.g. the
`pingcap.com` apiGroup rule narrows from "all resources, all verbs" to the exact
CRD kinds the operator actually manages (`backups`, `backupschedules`,
`compactbackups`, `dmclusters`, `restores`, `tidbclusters`, `tidbdashboards`,
`tidbdashboards/status`, `tidbinitializers`, `tidbmonitors`, `tidbngmonitorings`,
`tidbngmonitorings/status`) and seven explicit verbs instead of `*`. Also adds an
opt-in `controllerManager.automountServiceAccountToken` toggle (defaults `true`,
matching prior behavior — not exercised by this Application's own `valuesObject`,
which doesn't touch it). `values.yaml`'s only other change is the two bundled
image tags (`operatorImage`, `tidbBackupManagerImage`) moving `v1.6.5` → `v1.6.6`.
This Application's own `valuesObject` overrides (`resources`, `scheduler`,
`admissionWebhook.create: false`) are all still valid keys at the new pin — no
schema break. Commit `38b5857` ("bump TiDB Operator to v1.6.6, TiDB to v8.5.7")
confirms the recommended paired TiDB database version already matches this lab's
own separately-pinned `tidb-cluster.yaml` version (`v8.5.7`, governed by
ADR-0032) — no drift introduced there either.

## Fix

`gitops/platform/tidb-operator.yaml`: `targetRevision: 1.6.5` → `1.6.6`, with an
inline comment documenting the ADR-0031 in-scope rationale and the real diff
summary above. Updated `docs/dependency-register.md`'s TiDB Operator row "Last
reviewed" cell. No ADR-0031 re-evaluation-log entry needed — its own text scopes
that log to major-line (`1.x` → `2.x`) decisions only; this is an ordinary
same-line patch bump, explicitly pre-authorized by the ADR's own Consequences
section.

## Recurrence prevention

No test asserts `tidb-operator`'s specific chart-version pin today (checked
`tests/tidb-admin-extras.bats`, `tests/tidb-cluster.bats` — neither references
`1.6.5`/`1.6.6`) — TiDB is a heavy on-demand component with no live-cluster
verification available to this remote session, and per this repo's existing
convention a chart-version-only bump with no schema/behavior change to our own
`valuesObject` doesn't need a dedicated pin-assertion test the way a
security-flip or breaking-change bump would. `make ci` (terraform/kustomize/
manifest validation, clusterless) confirms the YAML stays well-formed.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration
items; `verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631;
capstone Deployment removal on unconfirmed issue #633) — re-checked directly,
both still open, no new comment since 2026-08-11.

## ADR-0004 caveat

This remote clusterless session verified the chart diff directly against real
upstream source (a full clone at both tags) but cannot verify a live
`tidb-operator` reconciles cleanly against the new RBAC shape on an actual
cluster — TiDB is on-demand and this session has no cluster access. Rollback
path: revert `targetRevision` to `1.6.5`; the next `make tidb-operator-up` (or
ArgoCD sync of an already-running instance) picks up the prior chart version —
no data-plane impact, this only touches the operator's own RBAC/image, not
`TidbCluster` resources or their PVs.

## PR

https://github.com/tooming/k8s-anywhere/pull/1159
