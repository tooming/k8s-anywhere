# upgrade(velero): 8.4.0 → 8.7.2

Routine upgrade-drafter sweep (executor STEP 6b fallback — the "Now / next" lane was
gated again this cycle; a CVE sweep across several other on-demand components
this cycle — Velero, Argo Rollouts, cert-manager Certificates, Harbor's admin
credential wiring, TiDB, Longhorn — turned up no new applicable finding, so this
run's deliverable is a routine, low-risk chart currency bump instead).

## What changed

`gitops/platform/velero.yaml`'s `targetRevision` bumped from `8.4.0` to `8.7.2` —
latest stable patch on the `8.x` chart line, deliberately not crossing the `9.x`
major bump (out of scope for a routine bump; would need its own architect
decision). No `valuesObject` changes.

## Why this version

`appVersion` is **unchanged** (`1.15.2`) between chart `8.4.0` and `8.7.2` — this
is a chart-packaging-only bump, no change to the Velero application code itself.
Diffed the chart's `values.yaml` between both tags (sparse git fetch of
`vmware-tanzu/helm-charts` — the chart repo's own `index.yaml` endpoint is
proxy-blocked in this sandbox): purely additive (`runtimeClassName`,
`pluginVolumePath`, a new commented-out example), no renamed or removed keys.
Every `valuesObject` key this repo sets (`credentials.*`, `configuration.*`,
`deployNodeAgent`, `resources.*`, `nodeAgent.*`) was individually verified present
and unchanged at the new pin before landing this.

## Also checked this cycle (no action needed)

Continued this session's CVE/compatibility sweep across on-demand components not
yet checked:
- **Argo Rollouts** (capstone `Rollout` + `success-rate` `AnalysisTemplate`):
  verified the `Metric` struct fields (`name`, `interval`, `successCondition`,
  `failureLimit`, `provider.prometheus`) against the pinned `v1.9.1` API types —
  all match, no wrong-key bug.
- **cert-manager** `Certificate` resources (wildcard leaf + root CA): standard,
  long-stable CRD fields (`secretName`, `dnsNames`, `privateKey`, `issuerRef`,
  `isCA`, `duration`, `renewBefore`) — all correct.
- **Harbor** — [CVE-2026-4404](https://www.sentinelone.com/vulnerability-database/cve-2026-4404/)
  (critical, CVSS 9.4: hardcoded default `admin`/`Harbor12345` credentials).
  Already mitigated in this repo: `gitops/platform/harbor.yaml` sets
  `existingSecretAdminPassword: harbor-admin-creds` /
  `existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD`, rendered by
  `gitops/secrets/harbor-admin-externalsecret.yaml` from a Vault-generated random
  credential (`scripts/vault-bootstrap.sh` seeds `secret/harbor/admin`) — the
  vulnerable default is never actually used.
- **TiDB** / **Longhorn**: no specific 2026 CVE found for either project in this
  sweep.

## Validation

`make ci` — fully green. `bats tests/velero.bats`: 56/56 pass, including the
updated chart-pin assertions.

## PR

(filled in after PR creation)
