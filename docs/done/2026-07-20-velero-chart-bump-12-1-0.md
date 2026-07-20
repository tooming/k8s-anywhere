# Velero chart major bump `8.7.2` → `12.1.0`

RFC #617 — architect decision 2026-07-20, actioning ADR-0021's 2026-07-18
Re-evaluation log flip condition. **No prerequisites — executor may pick up
immediately.** Implements RFC #617's binding spec exactly: bumped
`gitops/platform/velero.yaml`'s `targetRevision` from `8.7.2` to `12.1.0`
(`appVersion` `1.15.2` → `1.18.1`). RFC #617 already verified, field-for-field
against the real chart source at that tag, that every key this repo's
`valuesObject` sets (`credentials.{useSecret,existingSecret}`,
`configuration.{defaultVolumesToFsBackup,features,uploaderType,
backupStorageLocation}`, `deployNodeAgent`, `resources`, `nodeAgent.resources`)
is unchanged across the `8.x` → `12.x` jump — no `valuesObject` schema change
was required, this is a version-number-only bump.

Updated `gitops/platform/velero.yaml`'s own in-file comment with the new
bump's rationale (appended alongside the prior `8.4.0`→`8.7.2` bump's comment,
same pattern). Extended `tests/velero.bats`'s chart-pin assertions to the new
version (`targetRevision: 12\.[0-9]+\.` regex + an exact `12.1.0` assertion,
replacing the prior `8.x` assertions). Appended a dated entry to ADR-0021's
`## Re-evaluation log` recording the bump landing and resolving the flip
condition, and synced the ADR's "Chart + version" summary section (which still
read the original authoring-time "v8.4.x" note) to the current pin — the same
stale-doc class this run's earlier janitor cycle (PR #616) fixed for
ADR-0020's Argo Rollouts entry.

**ADR-0004 caveat.** This remote clusterless session cannot verify Velero
actually starts cleanly, or that a real backup+restore cycle succeeds
post-bump, on a live cluster. Rollback path: revert `targetRevision` to
`8.7.2`; ArgoCD self-heals within its sync interval. Velero's Garage backups
are content-addressed object storage, so a revert loses no existing backup
data — the rollback is purely a controller-version change, not a data
operation.

`make ci` passes.

Closes #617.

## PR

https://github.com/tooming/k8s-anywhere/pull/620
