# Planner run 2026-07-08 — Harbor day-0 credential seam

## Why this run fired the planner fallback

The executor lane had three unchecked 🟢 items, all already taken by open PRs
(#342 `auto/architecture-doc-harbor-update`, #343 `auto/o2-np-coverage-loop`,
#344 `auto/o2-pss-coverage-loop`). No intake issues were open. The planner
fallback activated to refill the lane.

## Gap analysis finding

**ADR-0024** mandates that Harbor credentials flow from Vault via ESO — no
plaintext credentials in CI (§"Relationship to capstone"). However:

- `scripts/vault-bootstrap.sh` seeds `secret/artifactory/registry` (line 79)
  but has no corresponding `secret/harbor/admin` or `secret/harbor/registry`
  block — Harbor credential paths are completely absent from day-0 bootstrap.
- `gitops/platform/harbor.yaml` uses the hard-coded default password
  `Harbor12345` with no `existingSecretAdminPassword` reference.
- `gitops/secrets/` has `harbor-s3-externalsecret.yaml` and
  `harbor-valkey-externalsecret.yaml` but no `harbor-admin-externalsecret.yaml`.

This means `auto/harbor-capstone-rewire` — when the maintainer eventually
confirms the 12 GB budget gate — would encounter a missing Vault path with no
seeded credential for CI image-push. The new item `auto/harbor-bootstrap-credentials`
fills this gap and is immediately buildable (no cluster, no prerequisites).

## Item added

`auto/harbor-bootstrap-credentials` — inserted in "Now / next" immediately
before `auto/harbor-capstone-rewire` (the capstone rewire item it unblocks).
Tier: 🟢 Green. Clusterless: all deliverables are YAML/shell edits + bats tests.
