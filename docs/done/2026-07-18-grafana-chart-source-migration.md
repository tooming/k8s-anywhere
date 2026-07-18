# Migrate Grafana chart source off the deprecated grafana.github.io/helm-charts repo

RFC #544 (architect decision 2026-07-18, PR #545), absorbed into ROADMAP by
PR #546.

## What changed

`gitops/platform/observability-grafana.yaml`'s chart source:
- `repoURL: https://grafana.github.io/helm-charts` → `repoURL: https://grafana-community.github.io/helm-charts`
- `targetRevision: 10.5.15` → `targetRevision: 12.7.2`

The running Grafana image is **unchanged** — `valuesObject.image.tag` stays
pinned at `"13.0.1"` per the file's own documented history (ADR-0006's Git
Sync provider + a known 13.0.0 unified-storage migration bug for Git Sync
users). This is a chart-template/schema source bump only, not an app-version
bump.

## Why

Verified directly (ADR-0004): the old source's `grafana` chart entry at our
exact former pin (`grafana-10.5.15`) carries `deprecated: true` in its own
`Chart.yaml`, and its `README.md` states migration to
`grafana-community/helm-charts` completed 2026-01-30 — nearly six months
before this session (2026-07-18). The new source is actively maintained
(chart `12.7.2`, `appVersion: 13.1.0`, no deprecation flag). Staying on a
frozen, deprecated chart source means future template fixes and CVE-relevant
chart updates never reach this Application.

`observability-alloy.yaml` and `observability-pyroscope.yaml` also use the
old repoURL but were explicitly out of scope for this RFC — their own
dedicated source repos (`grafana/alloy`, `grafana/pyroscope`) show no
deprecation signal and their `main` branch chart versions match our current
pins exactly.

## Schema verification (ADR-0004)

Fetched both chart versions' `values.yaml` and `templates/_pod.tpl` directly
and confirmed every key our `valuesObject` sets is present, unchanged in
name and template wiring, between chart 10.5.15 (old source) and chart
12.7.2 (new source): `securityContext` (pod-level, `templates/_pod.tpl` line
13-14), `containerSecurityContext` (container-level, line 1265),
`initChownData`, `persistence`, `deploymentStrategy`, `extraConfigmapMounts`,
`extraEmptyDirMounts`, `extraInitContainers`, `grafana.ini` (including the
`provisioning`/`unified_storage` feature-toggle keys ADR-0006 depends on),
`datasources`, `dashboardProviders`, `dashboards.community`, `extraObjects`,
`admin`. Both chart versions' default `securityContext`/`containerSecurityContext`
blocks are byte-identical (`runAsNonRoot: true`, `runAsUser/runAsGroup/fsGroup: 472`,
`allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`,
`seccompProfile.type: RuntimeDefault`) — no schema break.

Updated the in-file comment referencing the verified chart tag
("grafana-10.5.15" → "grafana-12.7.2") and added a comment documenting the
migration and the deliberate image-tag decoupling.

## What was NOT verified (ADR-0004 caveat)

This remote clusterless session cannot verify the new chart actually
reconciles cleanly against a live cluster — the values-schema diff and
template read are the strongest verification available without a live
Grafana pod. Rollback path: revert `repoURL`/`targetRevision` to the old
pin (still resolvable, just frozen/deprecated, not deleted).

## Validation

`make ci` — same known pre-existing local bats failures as every prior cycle
this session (sandbox bats/yq toolchain mismatch, unrelated to this change).
GitHub Actions is the authoritative gate for this PR.

## PR

https://github.com/tooming/k8s-anywhere/pull/547
