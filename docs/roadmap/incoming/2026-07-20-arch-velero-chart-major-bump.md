- [ ] 🟡 **Velero chart major bump `8.7.2` → `12.1.0`** (RFC #617 — architect
  decision 2026-07-20, actioning ADR-0021's 2026-07-18 Re-evaluation log flip
  condition. **No prerequisites — executor may pick up immediately once
  groomed.**) Implement RFC #617's binding spec exactly: bump
  `gitops/platform/velero.yaml`'s `targetRevision` from `8.7.2` to `12.1.0`
  (`appVersion` `1.15.2` → `1.18.1`). RFC #617 already verified, field-for-field
  against the real chart source at that tag, that every key this repo's
  `valuesObject` sets (`credentials.{useSecret,existingSecret}`,
  `configuration.{defaultVolumesToFsBackup,features,uploaderType,
  backupStorageLocation}`, `deployNodeAgent`, `resources`,
  `nodeAgent.resources`) is unchanged across the `8.x` → `12.x` jump — no
  `valuesObject` schema change is required, this is a version-number-only bump.
  Update `gitops/platform/velero.yaml`'s own in-file comment (documents the
  prior `8.4.0`→`8.7.2` bump) with the new bump's rationale. Extend
  `tests/velero.bats`'s chart-pin assertion (add one if none exists — check
  first) to the new version. Append the RFC #617 acceptance-criteria's required
  dated entry to ADR-0021's `## Re-evaluation log` (the architect PR already
  added the 2026-07-20 "actioned as RFC #617" entry; add one more recording the
  bump itself landing, mirroring the two-entry pattern ADR-0020 used for its
  Argo Rollouts chart bump). PR body must document the ADR-0004 caveat: this
  remote clusterless session cannot verify Velero actually starts cleanly or
  that a real backup+restore cycle succeeds post-bump on a live cluster — call
  out the rollback path (revert `targetRevision`; ArgoCD self-heals; Velero
  backups are content-addressed in Garage so a revert doesn't lose existing
  backup data). `make ci` must pass. `docs/done/` entry required. Closes #617.
  (auto/velero-chart-bump-12-1-0)
