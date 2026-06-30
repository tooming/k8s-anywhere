# Harbor on-demand Application + namespace + Envoy route

Harbor CNCF OCI artifact registry wired as a non-auto-synced ArgoCD Application (ADR-0024,
RFC #297, supersedes ADR-0011). First slice of the Artifactory→Harbor migration.

Add `gitops/platform/harbor.yaml`: a **non-auto-synced** ArgoCD `Application` (NO
`automated:` block — mirrors `gitops/platform/artifactory.yaml`), chart `harbor` from
`https://helm.goharbor.io` (pinned chart v1.16.0 / appVersion v2.12.x), namespace `harbor`.
`valuesObject` minimal profile per ADR-0024:
- `trivy.enabled: false` (cluster scanning handled by Trivy Operator, ADR-0022)
- `notary.enabled: false` (out of scope first cut)
- `expose.type: clusterIP` + `expose.tls.enabled: false` (Envoy HTTPRoute fronts ingress, ADR-0008)
- `externalURL: http://harbor.127.0.0.1.nip.io:8000`
- `persistence.imageChartStorage.type: s3` with Garage S3 backend (ADR-0002), bucket
  `harbor-registry`, regionendpoint `http://garage.storage.svc.cluster.local:3900`
- `database.type: internal` (bundled Postgres acceptable first cut)
- `redis.type: external` pointing at platform Valkey `valkey.data.svc.cluster.local:6379`
  (ADR-0018 — `redis` is the Harbor chart's own API parameter name for its cache dependency;
  the actual backend is platform Valkey, not a Redis deployment)
- S3 credentials via `registry.registry.extraEnvVarsSecret: harbor-s3-creds` (ESO-rendered
  Secret from Vault `secret/harbor/s3`; Docker Distribution registry2 reads
  `REGISTRY_STORAGE_S3_ACCESSKEY` / `REGISTRY_STORAGE_S3_SECRETKEY` env vars to override
  the empty config values — credentials never inline, per ADR-0002)

Add `gitops/platform/harbor-extras.yaml` (auto-synced, sync-wave 0) sourcing
`gitops/harbor` so the namespace PSA floor + HTTPRoute exist before `make harbor-up`.

Add `gitops/harbor/namespace.yaml` with PSA **`restricted`** + `enforce-version: latest`
(Harbor core/registry/jobservice run as non-root UID 10000; bundled Postgres uses Bitnami
non-root UID 1001 — Go runtime advances the hardening track vs. Artifactory's `baseline`
carve-out, per ADR-0024 §PSA profile).

Add `gitops/harbor/route.yaml`: Envoy `HTTPRoute` `harbor.127.0.0.1.nip.io` (ADR-0008,
parentRef `eg`/`lab-gateway`) backendRef'ing the Harbor unified Service on port 80.

Wire Harbor into the Grafana "Lab UIs" panel (`grafana/dashboards/stack-health.json`);
`make lab-ui-check` stays green.

Update `scripts/garage-bootstrap.sh`: create `harbor-key` Garage access key, grant on
`harbor-registry` bucket, create the `harbor-registry` bucket, store rendered creds at
Vault path `secret/harbor/s3` (mirrors `inkless/s3` + `velero/s3` flow).

Add `gitops/secrets/harbor-s3-externalsecret.yaml` (ESO ExternalSecret rendering the
`harbor-s3-creds` Secret with `REGISTRY_STORAGE_S3_ACCESSKEY` and
`REGISTRY_STORAGE_S3_SECRETKEY` from Vault `secret/harbor/s3`).

Add `tests/harbor.bats`: Application shape (no automated block), chart source + version pin,
trivy/notary disabled, storage type s3, Garage endpoint, harbor-s3-creds reference, namespace
PSA labels (restricted), HTTPRoute, ExternalSecret Vault path, garage-bootstrap.sh seam,
Lab UIs panel entry.

Update `docs/dependency-tree.md` with a HARBOR subgraph + Garage S3 edge + Envoy HTTPRoute edge.

**ADR guard note**: The `redis:` key in `harbor.yaml` is the Harbor chart's own API parameter
name for its external cache dependency — it is not deploying Redis. `type: external` redirects
Harbor to use platform Valkey (ADR-0018). ADR-0024 §"Relationship to existing ADRs" explicitly
authorizes this pattern. This is a structural false positive from the chart's own API naming.

## PR

#306
