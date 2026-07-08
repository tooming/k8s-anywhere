# Harbor day-0 credential seam — admin + CI registry secrets

**Harbor day-0 credential seam — admin + CI registry secrets** (RFC #297 / ADR-0024 —
architect decision 2026-06-30; **no prerequisites — executor may pick up immediately**;
**unblocks `auto/harbor-capstone-rewire`**). The Harbor ArgoCD Application
(`gitops/platform/harbor.yaml`) currently uses the hard-coded default password
`Harbor12345` with no `existingSecretAdminPassword` reference, and `vault-bootstrap.sh`
seeds no Harbor credential path (only `secret/artifactory/registry` exists). This item
adds the missing day-0 seam, parallel to the velero-key + inkless-key pattern already in
`garage-bootstrap.sh`: (1) extend `scripts/vault-bootstrap.sh` to seed
`secret/harbor/admin` (`admin-user=admin`, `admin-password=<rand-hex-16>`) and
`secret/harbor/registry` (`username=admin`, `password=<rand-hex-16>`) — both idempotent
(`kv get ... || kv put ...`), exact parallel to the existing `secret/artifactory/registry`
block at line 79; (2) add `gitops/secrets/harbor-admin-externalsecret.yaml` (namespace
`harbor`, target Secret `harbor-admin-creds`, keys `HARBOR_ADMIN_PASSWORD` +
`HARBOR_ADMIN_USER` from `secret/harbor/admin`); (3) patch `gitops/platform/harbor.yaml`
to set `existingSecretAdminPassword: harbor-admin-creds` and
`existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD`; (4) add
`tests/harbor-bootstrap.bats` (clusterless structural: `vault-bootstrap.sh` seeds both
paths, `harbor-admin-externalsecret.yaml` exists, `harbor.yaml` references
`existingSecretAdminPassword`); (5) note `secret/harbor/registry` in the
`docs/dependency-tree.md` Day-0 bootstrap section.

## PR

#347
