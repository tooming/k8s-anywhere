# Dependency & integration tree

How every piece of the lab depends on and integrates with every other piece.
Derived from the GitOps source of truth (sync-wave annotations, `ExternalSecret`
`remoteRef`s, `HTTPRoute`s, the bootstrap scripts and `make up`), so it matches what
ArgoCD reconciles into the cluster. Two views: the **runtime integration graph** and
the **day-0 bootstrap chain**.

## Integration graph (who talks to whom)

```mermaid
graph TD
  classDef boot fill:#ffe0ef,stroke:#b3598a,color:#000
  classDef gitops fill:#dceeff,stroke:#3b78b3,color:#000
  classDef sec fill:#fff6cc,stroke:#b39b00,color:#000
  classDef store fill:#dcf5dc,stroke:#3b9b3b,color:#000
  classDef obs fill:#e6e6ff,stroke:#5b5bc0,color:#000
  classDef ing fill:#ffe6ff,stroke:#b35bb3,color:#000
  classDef cloud fill:#e0f7f7,stroke:#3bb3b3,color:#000
  classDef ondemand fill:#eeeeee,stroke:#999,color:#555
  classDef data fill:#ffe9d6,stroke:#cc7a30,color:#000

  user(["You — browser"])
  frontdoor["Front door — nginx :8000<br/>(off-cluster docker, stable entry)"]:::ing

  subgraph HOST["Host / runtime"]
    colima["Colima VM (vz, 12G)"]
    dockerd["Docker daemon"]
    colima --> dockerd
  end

  subgraph BOOT["Day-0 bootstrap — imperative (Terraform/Terragrunt + scripts)"]
    tg["Terragrunt"]
    scripts["scripts: gitlab-pat,<br/>vault-bootstrap, garage-bootstrap"]
  end

  gitlab["GitLab omnibus :8929<br/>git source of truth"]:::boot
  k3d["k3d cluster (k3s-in-Docker)"]:::boot
  argocd["ArgoCD — GitOps engine"]:::gitops

  dockerd --> k3d
  dockerd --> gitlab
  tg -->|creates| k3d
  tg -->|helm install| argocd
  tg -->|"project + repo deploy-token"| gitlab
  argocd -->|"clone (repo secret)"| gitlab
  scripts -->|init/unseal/seed| vault
  scripts -->|layout/keys/buckets| garage
  argocd ==>|"app-of-apps · sync-waves 0-5"| AOA

  subgraph AOA["In-cluster workloads — ArgoCD-managed"]
    subgraph SEC["Secrets"]
      vault["Vault (KV v2)"]:::sec
      eso["External Secrets Operator<br/>ClusterSecretStore 'vault'"]:::sec
    end
    subgraph STORE["Storage"]
      garage["Garage S3 :3900<br/>buckets: mimir, mimir-ruler,<br/>loki, tempo, pyroscope"]:::store
      s3man["s3manager (bucket UI)"]:::store
    end
    subgraph OBS["Observability — LGTMP"]
      nodeexp["node-exporter"]:::obs
      ksm["kube-state-metrics"]:::obs
      alloy["Alloy (collector)"]:::obs
      mimir["Mimir (metrics)"]:::obs
      loki["Loki (logs)"]:::obs
      tempo["Tempo (traces)"]:::obs
      pyro["Pyroscope (profiles)"]:::obs
      grafana["Grafana"]:::obs
    end
    subgraph CLOUD["Cloud / platform-eng"]
      moto["moto — AWS mock :5000"]:::cloud
      ack["ACK (S3 controller)"]:::cloud
      kro["KRO — S3BucketClaim RGD"]:::cloud
    end
    subgraph TIDB["TiDB — on-demand (manual sync only)"]
      tidbop["TiDB Operator<br/>(tidb-admin ns)"]:::ondemand
      tidbcluster["TiDB Cluster<br/>1×PD + 1×TiKV + 1×TiDB<br/>(tidb ns)"]:::ondemand
      tidbdemo["TiDB Demo App<br/>(tidb ns)"]:::ondemand
    end
    subgraph ARTIF["Artifactory — on-demand (manual sync only)"]
      artifactory["Artifactory OSS<br/>artifact registry + Docker registry<br/>(artifactory ns)"]:::ondemand
    end
    subgraph CAPSTONE["Capstone — build pipeline (steps 1–4 done; step 5 pending)"]
      capstoneci["GitLab CI<br/>build-and-push pipeline<br/>(.gitlab-ci.yml)"]:::ondemand
      capstoneapp["capstone app<br/>Deployment + Service<br/>(capstone ns)"]:::gitops
    end
    subgraph ISTIO["Istio ambient — on-demand (manual sync only)"]
      istiobase["istio-base<br/>CRDs + RBAC<br/>(istio-system ns)"]:::ondemand
      istiocni["istio-cni<br/>node CNI plugin<br/>(ambient mode)"]:::ondemand
      istiod["istiod<br/>control plane<br/>(ambient profile)"]:::ondemand
      ztunnel["ztunnel<br/>per-node L4 proxy<br/>(DaemonSet)"]:::ondemand
      kiali["Kiali<br/>service mesh UI<br/>(istio-system ns)"]:::ondemand
    end
    subgraph LONGHORN["Longhorn — on-demand (manual sync only)"]
      longhornmgr["longhorn-manager<br/>DaemonSet + CSI driver<br/>(longhorn-system ns)"]:::ondemand
      longhornui["longhorn-ui<br/>volume/snapshot dashboard"]:::ondemand
    end
    subgraph DATA["Data layer — always-on (data ns)"]
      rabbitmq["RabbitMQ<br/>broker + mgmt UI + prometheus"]:::data
      redis["Redis<br/>cache/KV + redis_exporter"]:::data
      datademo["data-demo<br/>(traffic generators)"]:::data
    end
    envoy["Envoy Gateway"]:::ing
    demo["demo / hello<br/>(HotROD — OTel trace producer)"]
  end

  %% --- secret chain (ExternalSecret <- Vault path) ---
  vault -->|"k8s auth, role eso"| eso
  eso -->|"garage-secrets ← garage/server"| garage
  eso -->|"garage-s3 ← garage/s3"| mimir
  eso -->|garage-s3| loki
  eso -->|garage-s3| tempo
  eso -->|garage-s3| pyro
  eso -->|garage-s3| s3man
  eso -->|"ack-aws-creds ← aws/moto"| ack
  eso -->|"grafana-admin ← grafana/admin"| grafana
  eso -->|"tidb-demo-creds ← tidb/demo"| tidbdemo
  eso -->|"rabbitmq-creds ← rabbitmq/default"| rabbitmq
  eso -->|"redis-creds ← redis/default"| redis
  eso -->|"data-demo-creds ← rabbitmq/default + redis/default"| datademo
  eso -.->|"artifactory-registry ← artifactory/registry (capstone ns)"| capstoneci

  %% --- observability data flow ---
  nodeexp -->|scrape| alloy
  ksm -->|scrape| alloy
  alloy -->|"metrics (X-Scope-OrgID lab)"| mimir
  alloy -->|logs| loki
  alloy -->|profiles| pyro
  demo -->|"OTLP :4318"| tempo
  mimir -->|S3| garage
  loki -->|S3| garage
  tempo -->|S3| garage
  pyro -->|S3| garage
  mimir -->|datasource| grafana
  loki -->|datasource| grafana
  tempo -->|datasource| grafana
  pyro -->|datasource| grafana

  %% --- cloud / platform-eng ---
  kro -->|composes| ack
  ack -->|"S3 API :5000"| moto

  %% --- TiDB on-demand chain ---
  tidbop -.->|"manages CRDs"| tidbcluster
  tidbcluster -.->|"DB endpoint"| tidbdemo

  %% --- Artifactory on-demand + capstone CI pipeline ---
  envoy -.->|"artifactory.127.0.0.1.nip.io (on-demand)"| artifactory
  gitlab -.->|"capstone CI build (step 1)"| capstoneci
  capstoneci -.->|"docker push hello:SHA (on-demand)"| artifactory
  artifactory -.->|"image pull (step 2)"| capstoneapp
  envoy -->|"capstone.127.0.0.1.nip.io (step 3)"| capstoneapp
  capstoneapp -.->|"OTLP :4318 (step 4)"| tempo
  mimir -.->|"capstone pod metrics (step 4)"| grafana
  loki -.->|"capstone logs (step 4)"| grafana

  %% --- Istio ambient on-demand chain ---
  istiobase -.->|"CRDs"| istiocni
  istiobase -.->|"CRDs"| istiod
  istiocni -.->|"node capture"| ztunnel
  istiod -.->|"control plane"| ztunnel
  istiod -.->|"mesh config"| kiali
  envoy -.->|"kiali.127.0.0.1.nip.io (on-demand)"| kiali

  %% --- Longhorn on-demand ---
  longhornmgr -.->|"manages volumes"| longhornui
  envoy -.->|"longhorn.127.0.0.1.nip.io (on-demand)"| longhornui

  %% --- data layer (always-on) ---
  rabbitmq -->|"scrape :15692"| alloy
  redis -->|"scrape :9121"| alloy
  datademo -->|"AMQP publish/consume"| rabbitmq
  datademo -->|"SET/GET/INCR"| redis

  %% --- ingress (north-south) ---
  user --> frontdoor
  frontdoor --> envoy
  envoy -->|argocd.127.0.0.1.nip.io| argocd
  envoy -->|localhost| grafana
  envoy -->|vault.127.0.0.1.nip.io| vault
  envoy -->|s3.127.0.0.1.nip.io| s3man
  envoy -->|moto.127.0.0.1.nip.io| moto
  envoy -.->|"tidb-demo.127.0.0.1.nip.io (on-demand)"| tidbdemo
  envoy -->|rabbitmq.127.0.0.1.nip.io| rabbitmq
```

## Day-0 bootstrap chain (`make up` — the only imperative steps)

Everything below step 6 is reconciled by ArgoCD from GitLab; steps 1–8 are the
non-GitOps seam (you can't GitOps the GitOps engine or its git source into being).

```
make up
└─ 1 colima-up          Colima VM (Docker runtime)
   └─ 2 tfstate-up       off-cluster Garage for TF state              [docker compose]
      └─ 3 cluster-up       k3d cluster                               [Terragrunt → s3 backend]
         └─ 4 argocd        ArgoCD (GitOps engine)                    [Terraform/Helm]
            └─ 5 gitlab-up  GitLab omnibus (git source)               [docker compose]
               └─ 6 gitlab-configure  project + ArgoCD repo deploy-token + git push   [Terraform + git]
                  └─ 7 root-app       app-of-apps planted             [kubectl apply]
                     ├─ 8 vault-bootstrap   init/unseal; seed secret/garage/server,
                     │                      aws/moto, grafana/admin, tidb/demo,
                     │                      rabbitmq/default, redis/default;
                     │                      k8s auth + eso role; kick ESO
                     └─ 9 garage-bootstrap  layout + S3 key + buckets → writes vault:garage/s3
                        └─ ESO syncs Vault→Secrets ⇒ Garage, Mimir, Loki, Tempo,
                           Pyroscope, ACK, Grafana converge on their own
```

> **Why a second, off-cluster Garage?** The in-cluster Garage is created *by* the
> Terraform in steps 3–6, so it can't also be that Terraform's state backend without a
> bootstrap loop. The state Garage (step 2) is a *separate instance* that comes up first
> and lives off-cluster (like GitLab and the front door), breaking the loop. Same engine,
> different purpose. See [docs/platform-products.md](platform-products.md) for the
> build-vs-product distinction.

## ArgoCD apply order (sync-waves, from `gitops/platform/`)

| Wave | Apps | Why this wave |
|------|------|---------------|
| 0 | envoy-gateway, demo | Gateway API CRDs + controller; demo (no wave annotation, auto-synced) |
| 1 | vault, external-secrets, garage, mimir, kube-state-metrics, moto, lab-gateway | secret engine + ESO controller + storage + metrics store; shared Gateway (after Gateway API CRDs) |
| 2 | alloy, grafana, loki, tempo, pyroscope, node-exporter, external-secrets-config, vault-extras | collectors + stores + UI; ClusterSecretStore + ESO bindings; Vault add-ons (all after wave 1 deps) |
| 3 | ack-s3, kro, s3manager, rabbitmq, redis | controllers/abstractions + bucket UI; data layer (after the ClusterSecretStore in wave 2) |
| 4 | ack-resources, data-demo | ACK `Bucket` CRs (need the controller); data-demo traffic generators (need rabbitmq + redis) |
| 5 | kro-resources | KRO instances (need the RGD + ACK) |
| — | tidb-operator *(on-demand)* | CRD controller for TiDB; discovered by ArgoCD but **manual-sync only** — use `make tidb-operator-up` |
| — | tidb-cluster *(on-demand)* | `TidbCluster` CR (1×PD + 1×TiKV + 1×TiDB); manual-sync only — use `make tidb-up` (requires tidb-operator) |
| — | tidb-demo *(on-demand)* | Demo app reading TiDB creds from Vault via ExternalSecret; manual-sync only — use `make tidb-demo-up` |
| — | artifactory *(on-demand)* | JFrog Artifactory OSS artifact + Docker registry (chart `jfrog/artifactory-oss` from `charts.jfrog.io`); manual-sync only — use `make artifactory-up` |
| — | artifactory-extras *(on-demand)* | Envoy HTTPRoute for `artifactory.127.0.0.1.nip.io`; paired with the artifactory Application — use `make artifactory-up` |
| — | istio-base *(on-demand, step 1)* | Istio CRDs + cluster-scoped RBAC (chart `istio/base` from `istio-release.storage.googleapis.com/charts`); manual-sync only — use `make istio-up` |
| — | istio-cni *(on-demand, step 2)* | Istio CNI node plugin, ambient profile (chart `istio/cni`); must precede istiod — use `make istio-up` |
| — | istiod *(on-demand, step 3)* | Istio control plane, ambient profile (chart `istio/istiod`); no sidecar injection (ADR-0012) — use `make istio-up` |
| — | ztunnel *(on-demand, step 4)* | Per-node L4 proxy DaemonSet implementing ambient mesh data plane (chart `istio/ztunnel`) — use `make istio-up` |
| — | kiali *(on-demand)* | Service mesh observability UI (chart `kiali-server` from `https://kiali.org/helm-charts`, v1.89.0); anonymous auth; connects to Mimir Prometheus API; Envoy HTTPRoute `kiali.127.0.0.1.nip.io` — use `make kiali-up` (requires `istio-up`) or `make mesh-up` |
| — | kiali-extras *(on-demand)* | Envoy HTTPRoute for `kiali.127.0.0.1.nip.io`; paired with the kiali Application — use `make kiali-up` |
| — | longhorn *(on-demand)* | CNCF distributed block storage + CSI driver (chart `longhorn/longhorn` v1.7.2 from `https://charts.longhorn.io`, namespace `longhorn-system`; replica count 1 for single-node lab); manual-sync only — use `make longhorn-up` |
| — | longhorn-extras *(on-demand)* | Envoy HTTPRoute for `longhorn.127.0.0.1.nip.io`; paired with the longhorn Application — use `make longhorn-up` |

> Sync-waves are ArgoCD's **apply** order. The **runtime** secret dependency
> (Vault must be *bootstrapped* before ESO can sync) is enforced by the day-0
> chain above, not by waves — which is why `vault-bootstrap` kicks ESO.

## Integration edges, grounded

| Edge | Type | Source of truth |
|------|------|-----------------|
| ArgoCD → GitLab | clone via `repo-gitlab-gitops` secret | Terraform `gitlab-config` |
| Vault → ESO | k8s auth, role `eso`, policy `eso-read` | `scripts/vault-bootstrap.sh` |
| ESO → garage-secrets | `← vault:garage/server` | `gitops/secrets/garage-externalsecrets.yaml` |
| ESO → garage-s3 (Mimir/Loki/Tempo/Pyroscope/storage) | `← vault:garage/s3` | `gitops/secrets/` |
| ESO → ack-aws-creds | `← vault:aws/moto` | `gitops/secrets/ack-creds.yaml` |
| ESO → grafana-admin | `← vault:grafana/admin` (admin user + password) | `gitops/secrets/grafana-admin-externalsecret.yaml` |
| ESO → tidb-demo-creds *(on-demand)* | `← vault:tidb/demo` (username + password) | `gitops/tidb-demo/externalsecret.yaml` |
| Mimir/Loki/Tempo/Pyroscope → Garage | S3 backend `garage.storage.svc:3900` | each component's config |
| Alloy → Mimir/Loki/Pyroscope | remote_write / push | `gitops/observability/alloy` |
| hello (HotROD) → Tempo | OTLP HTTP `:4318` (`OTEL_EXPORTER_OTLP_ENDPOINT`) | `gitops/apps/demo/deployment.yaml` |
| ACK → moto | S3 API `moto.moto.svc:5000` | `gitops/ack`, ACK chart values |
| KRO → ACK | `S3BucketClaim` RGD composes a `Bucket` | `gitops/kro` |
| Front door :8000 → Envoy → UIs | `HTTPRoute` host-routing | `gitops/network`, per-app routes |
| Envoy → tidb-demo.127.0.0.1.nip.io *(on-demand)* | HTTPRoute | `gitops/tidb-demo/route.yaml` |
| ESO → rabbitmq-creds | `← vault:rabbitmq/default` (username + password) | `gitops/data/rabbitmq/externalsecret.yaml` |
| ESO → redis-creds | `← vault:redis/default` (password) | `gitops/data/redis/externalsecret.yaml` |
| ESO → data-demo-creds | `← vault:rabbitmq/default + redis/default` | `gitops/data/demo/externalsecret.yaml` |
| Alloy → RabbitMQ / Redis | scrape `:15692` / `:9121` → Mimir | `gitops/platform/observability-alloy.yaml` |
| data-demo → RabbitMQ / Redis | AMQP publish/consume · Redis SET/GET/INCR | `gitops/data/demo/` |
| Envoy → rabbitmq.127.0.0.1.nip.io | HTTPRoute (management UI) | `gitops/data/rabbitmq/route.yaml` |
| Envoy → artifactory.127.0.0.1.nip.io *(on-demand)* | HTTPRoute | `gitops/artifactory/route.yaml` |
| Envoy → kiali.127.0.0.1.nip.io *(on-demand)* | HTTPRoute | `gitops/kiali/route.yaml` |
| istiod → Kiali *(on-demand)* | mesh config (xDS endpoint) | `gitops/platform/kiali.yaml` values |
| Envoy → longhorn.127.0.0.1.nip.io *(on-demand)* | HTTPRoute | `gitops/longhorn/route.yaml` |
| ESO → artifactory-registry *(capstone)* | `← vault:artifactory/registry` (username + password) | `gitops/secrets/artifactory-registry-externalsecret.yaml` |
| GitLab CI → Artifactory *(capstone step 1)* | docker push `hello:SHA` via `.gitlab-ci.yml` | `.gitlab-ci.yml` |
| Artifactory → capstone app *(capstone step 2)* | image pull `docker-local/hello:latest` via `imagePullSecret` | `gitops/apps/capstone/deployment.yaml` |
| Envoy → capstone.127.0.0.1.nip.io *(capstone step 3)* | HTTPRoute | `gitops/apps/capstone/route.yaml` |
| capstone app → Tempo *(capstone step 4)* | OTLP HTTP `:4318` (`OTEL_EXPORTER_OTLP_ENDPOINT`) | `gitops/apps/capstone/deployment.yaml` |
| Grafana dashboard — Lab — Capstone *(capstone step 4)* | Mimir metrics + Loki logs + Tempo traces | `grafana/dashboards/lab-capstone.json` |

## Notes
- **Front door** (`:8000`, nginx docker container) is off-cluster and **not**
  GitOps-managed — the stable entry that survives blue/green; it's the front-LB
  SPOF in [ADR-0005](decisions/adr-0005-spof-recreate-over-ha.md).
- **GitLab** is also off-cluster (docker), the git source ArgoCD reads from.
- **Tempo** receives traces from the `hello` demo app (HotROD) via OTLP HTTP `:4318`. HotROD runs in `lab-demo` namespace and exports to `tempo.observability.svc.cluster.local:4318` via the standard `OTEL_EXPORTER_OTLP_ENDPOINT` env var. The "Lab — Traces" dashboard shows live span data.
- **TiDB Operator** (`gitops/platform/tidb-operator.yaml`) is on-demand / manual-sync — ArgoCD discovers the Application but does not auto-deploy the operator. Use `make tidb-operator-up` / `make tidb-operator-down`. Installs into namespace `tidb-admin`.
- **TiDB Cluster** (`gitops/platform/tidb-cluster.yaml`) is on-demand / manual-sync — deploys a minimal `TidbCluster` CR (1×PD + 1×TiKV + 1×TiDB, ~1.5 GB) into namespace `tidb`. Use `make tidb-up` / `make tidb-down`. Requires TiDB Operator running first. ADR-0003 note: production topology uses ≥3 PD + ≥3 TiKV + 2 TiDB; single replicas are the ADR-0005 lab trade-off.
- **TiDB Demo App** (`gitops/platform/tidb-demo.yaml`) is on-demand / manual-sync — deploys an nginx-based demo workload (namespace `tidb`) that reads TiDB credentials from Vault via `ExternalSecret tidb-demo-creds`. Demonstrates the Vault → ESO → Secret → Pod injection flow (learning-path step 4). HTTPRoute: `tidb-demo.127.0.0.1.nip.io`. Dashboard: "Lab — TiDB Demo App". Use `make tidb-demo-up` / `make tidb-demo-down`.
- **RabbitMQ** (`gitops/platform/rabbitmq.yaml`) is **always-on / auto-synced** — single-node broker (namespace `data`) with the management UI (`rabbitmq.127.0.0.1.nip.io`) and the `rabbitmq_prometheus` plugin (`:15692`, scraped by Alloy). Default user from Vault via `ExternalSecret rabbitmq-creds`. Dashboard: "Lab — RabbitMQ". ADR-0009. ADR-0003/0005 note: production runs a clustered broker with quorum queues; the single node is the single-host lab trade-off.
- **Redis** (`gitops/platform/redis.yaml`) is **always-on / auto-synced** — single-node cache/KV (namespace `data`) with auth via `--requirepass` (Vault → `ExternalSecret redis-creds`) and a `redis_exporter` sidecar (`:9121`, scraped by Alloy). No web UI. Dashboard: "Lab — Redis". ADR-0010. ADR-0003/0005 note: production uses Sentinel/Cluster; the single replica is the single-host lab trade-off.
- **data-demo** (`gitops/platform/data-demo.yaml`) is **always-on / auto-synced** — tiny generators (`redis-load`, `rabbitmq-load`, namespace `data`) that exercise Redis and RabbitMQ continuously so the dashboards show real traffic, not idle brokers. Credentials via `ExternalSecret data-demo-creds`.
- **Artifactory OSS** (`gitops/platform/artifactory.yaml` + `gitops/platform/artifactory-extras.yaml`) is **on-demand / manual-sync** — JFrog Artifactory OSS artifact registry (chart `jfrog/artifactory-oss` from `charts.jfrog.io`, namespace `artifactory`). JVM footprint (~1–2 GB) prevents auto-sync alongside the always-on stack (ADR-0011). HTTPRoute: `artifactory.127.0.0.1.nip.io`. Use `make artifactory-up` / `make artifactory-down`. The capstone pipeline (RFC #62) pushes images here. ADR-0003/0005 note: production runs clustered Artifactory HA; single node is the single-host lab trade-off.
- **Istio ambient mesh** (`gitops/platform/istio-base.yaml`, `istio-cni.yaml`, `istiod.yaml`, `ztunnel.yaml`) is **on-demand / manual-sync** — Istio ambient mesh (no per-pod sidecars; ADR-0012). Four ArgoCD Applications in deployment order: `istio-base` (CRDs) → `istio-cni` (CNI plugin, ambient) → `istiod` (control plane, ambient profile) → `ztunnel` (per-node L4 proxy DaemonSet). Charts from `https://istio-release.storage.googleapis.com/charts`, version 1.24.3. Total footprint ~480 MB. Namespace `istio-system`. Use `make istio-up` / `make istio-down`. ADR-0008 note: ztunnel shares the same Envoy data plane as the north-south gateway.
- **Kiali** (`gitops/platform/kiali.yaml` + `gitops/platform/kiali-extras.yaml`) is **on-demand / manual-sync** — service mesh observability UI (chart `kiali-server` v1.89.0 from `https://kiali.org/helm-charts`, namespace `istio-system`). Connects to Mimir's Prometheus-compatible API (`X-Scope-OrgID: lab`) for real-time service graph and traffic metrics. Exposed via Envoy HTTPRoute `kiali.127.0.0.1.nip.io`. Use `make kiali-up` / `make kiali-down` (requires `istio-up` first). For convenience, `make mesh-up` / `make mesh-down` bring up/down Istio + Kiali together in the correct order. ADR-0012; footprint ~200 MB.
- **Longhorn** (`gitops/platform/longhorn.yaml` + `gitops/platform/longhorn-extras.yaml`) is **on-demand / manual-sync** — CNCF distributed block storage + CSI driver (chart `longhorn/longhorn` v1.7.2 from `https://charts.longhorn.io`, namespace `longhorn-system`). Runs alongside `local-path` (the default provisioner) — adds a custom `StorageClass`, snapshot API, and volume UI; it does not replace `local-path` (ADR-0013). Default replica count: 1 (single-node lab, ADR-0005). Footprint ~350–400 MB; on-demand to stay within the 12 GB budget. Exposed via Envoy HTTPRoute `longhorn.127.0.0.1.nip.io`. Use `make longhorn-up` / `make longhorn-down`.
- **Capstone pipeline (steps 1–4 done)** — Step 1: `.gitlab-ci.yml` builds `gitops/apps/demo/Dockerfile` (HotROD wrapper) and pushes `docker-local/hello:$CI_COMMIT_SHORT_SHA` to Artifactory; credentials from Vault via masked CI vars. Step 2: `gitops/platform/capstone.yaml` (auto-synced ArgoCD Application) deploys the pipeline-built image from Artifactory to namespace `capstone`, using `imagePullSecret artifactory-registry` (ESO ExternalSecret). Step 3: `gitops/apps/capstone/route.yaml` exposes the app at `capstone.127.0.0.1.nip.io` via Envoy HTTPRoute (Gateway API). Step 4: `grafana/dashboards/lab-capstone.json` — "Lab — Capstone" dashboard with real pod/container metrics (Mimir/KSM/cAdvisor), Loki logs filtered to namespace `capstone`, and Tempo traces from the capstone app's OTLP instrumentation (ADR-0004: all data from real metrics). Step 5 (Vault secret + ExternalSecret for capstone app config) is still pending.
- Storage backups, true HA: out of scope (single host). See `docs/DR.md`.
