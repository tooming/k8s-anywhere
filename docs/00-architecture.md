# Architecture & Learning Path

## The big idea

Every tool in this lab has a job in a single coherent system: a **GitOps-driven
Kubernetes platform**. Rather than learning components in isolation, you build one
platform where each tool occupies a clear role — observable, secured, and recoverable
from code.

## Platform layers

The lab is structured in eight layers, each building on the one below. The same
grouping appears in the README stack table.

```
┌────────────────────────────────────────────────────────────────────────────┐
│  Bootstrap (IaC)                                                           │
│  Terraform · Terragrunt · k3d  — day-0 only; humans run this once         │
└──────────────────────────────────┬─────────────────────────────────────────┘
                                   │ creates cluster, installs ArgoCD,
                                   │ configures GitLab + Vault + Garage
                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  GitOps engine                                                             │
│  GitLab (git source of truth) ◄──── ArgoCD (app-of-apps reconciler)       │
│  ArgoCD watches gitops/ and converges the cluster to every commit          │
└──────────────────────────────────┬─────────────────────────────────────────┘
                                   │ sync-waves 0 → 5
                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  Always-on in-cluster workloads                                            │
│                                                                            │
│  INGRESS      Envoy Gateway  (Gateway API; north-south traffic)            │
│  SECRETS      Vault  ──►  External Secrets Operator  ──►  k8s Secrets     │
│  CNI / POLICY Cilium  (NetworkPolicy enforcement; default-deny per ns)     │
│  POLICY       Kyverno  (admission validation · mutation · verifyImages)    │
│  STORAGE      Garage (S3)  ──►  s3manager (bucket browser UI)             │
│  BACKUP       Velero  (cluster + PVC snapshots → Garage S3)               │
│  DATA         RabbitMQ  ·  Valkey (cache/KV)  ·  data-demo (generator)   │
│  CLOUD        moto (AWS mock)  ·  ACK (S3 controller)  ·  KRO             │
│  OBSERV.      Alloy  ──►  Mimir / Loki / Tempo / Pyroscope  ──►  Grafana  │
│               kube-state-metrics  ·  node-exporter                        │
│  SUPPLY CHAIN Trivy Operator  (CVE scanning · SBOM generation)            │
│  PROG. DELIV. Argo Rollouts  (Mimir-SLO-gated canary steps)               │
└────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  On-demand (manual make <name>-up / <name>-down)                          │
│  TiDB Operator · TiDB cluster · TiDB demo app                             │
│  Artifactory OSS (artifact + Docker registry)                             │
│  Istio ambient mesh (istio-base · istio-cni · istiod · ztunnel) · Kiali  │
│  Longhorn (distributed block storage)                                      │
│  Aiven Inkless (diskless Kafka)                                            │
│  Kargo (GitOps promotion pipelines)                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

## Who does what

Rows are grouped by layer, matching the README stack table.

### Bootstrap (IaC)

| Tool | Role in the platform |
|------|----------------------|
| **k3s** (via **k3d**) | The Kubernetes cluster — k3d runs k3s inside Docker containers so the lab runs on a single Mac without a cloud account. |
| **Terraform / Terragrunt** | Day-0 bootstrap only: creates the cluster, installs ArgoCD, configures GitLab projects and tokens, seeds Vault, and initialises Garage. Terragrunt keeps the Terraform modules DRY across environments. This is the *only* layer you run by hand — everything below is reconciled by ArgoCD. |

### GitOps engine

| Tool | Role in the platform |
|------|----------------------|
| **GitLab** | Git source of truth. Hosts the `gitops/` manifests and runs the CI pipeline (build → cosign sign → push to Artifactory). |
| **ArgoCD** | GitOps engine. Watches GitLab and makes the cluster match it (app-of-apps pattern). All workloads below arrive via ArgoCD, never by `helm install` or `kubectl apply`. |

### Ingress

| Tool | Role in the platform |
|------|----------------------|
| **Envoy Gateway** | North-south ingress. External traffic enters via the Kubernetes Gateway API (`HTTPRoute`s); Envoy routes it to in-cluster Services. `envoy-gateway-system-networkpolicy` default-deny overlay applies ADR-0016 to the namespace. (ADR-0008) |

### Secrets

| Tool | Role in the platform |
|------|----------------------|
| **Vault** | Secrets management (KV v2). Holds DB passwords, tokens, registry credentials, and the cosign private key. |
| **External Secrets Operator** | Bridges Vault to Kubernetes. A `ClusterSecretStore` points to Vault; `ExternalSecret` objects pull values into native k8s `Secret`s without embedding secrets in git. |

### Storage

| Tool | Role in the platform |
|------|----------------------|
| **Garage** | S3-compatible object store running in-cluster. Buckets: `mimir`, `mimir-ruler`, `loki`, `tempo`, `pyroscope`. Also the Velero backup target and Terraform-state backend. (ADR-0002, ADR-0007) |
| **s3manager** | Read-only web UI for browsing Garage buckets — visible on the Envoy front door. |

### Backup & restore

| Tool | Role in the platform |
|------|----------------------|
| **Velero** | Cluster resource + PVC backup/restore to Garage S3. Daily `Schedule` objects back up the `data`, `tidb`, `capstone`, and `vault` namespaces with the Kopia uploader. `make dr-restore` drives a verified restore drill. `velero-networkpolicy` default-deny overlay. (ADR-0021) |

### Observability (LGTMP)

| Tool | Role in the platform |
|------|----------------------|
| **Alloy** | OpenTelemetry-compatible telemetry collector. Scrapes Prometheus metrics from every workload (static targets for Kyverno, ESO, Argo Rollouts, Alloy self-metrics, KSM, node-exporter; dynamic scrape for pods); ships logs via Loki, traces via Tempo, profiles via Pyroscope. |
| **Mimir** | Long-term, horizontally-scalable metrics storage (Prometheus-compatible). All Grafana dashboards query Mimir with `X-Scope-OrgID: lab`. |
| **Loki** | Log aggregation. Alloy ships pod stdout/stderr logs here. |
| **Tempo** | Distributed tracing. OTLP-compatible ingest. |
| **Pyroscope** | Continuous profiling. |
| **Grafana** | Single pane of glass over Mimir, Loki, Tempo, and Pyroscope. Dashboards are managed via native Git Sync (ADR-0006) — no sidecar required. 28 lab dashboards cover every always-on component and the capstone pipeline. |
| **kube-state-metrics** | Exports Kubernetes resource state (pod phase, deployment replicas, PVC status, node readiness) as Prometheus metrics. |
| **node-exporter** | Exports host-level metrics (CPU, memory, disk, network) from the Colima VM. |

### Data layer

| Tool | Role in the platform |
|------|----------------------|
| **RabbitMQ** | Message broker with management UI. (ADR-0009) |
| **Valkey** | In-memory cache / key-value store; drop-in Redis replacement. (ADR-0018) |
| **data-demo** | Traffic generator that publishes messages to RabbitMQ and reads/writes Valkey — keeps the data-layer dashboards alive with real activity. |

### Cloud / platform-engineering

| Tool | Role in the platform |
|------|----------------------|
| **moto** | AWS API mock (S3, IAM, STS). ACK targets it instead of real AWS — no cloud account needed. |
| **ACK (S3 controller)** | AWS Controllers for Kubernetes. Reconciles `Bucket` CRs against the moto mock. |
| **KRO** | Kube Resource Orchestrator. Defines a `ResourceGraphDefinition` that turns a single `S3BucketClaim` CR into a coordinated set of ACK `Bucket` resources — a minimal platform-engineering composition layer. |

### CNI (bootstrap step)

| Tool | Role in the platform |
|------|----------------------|
| **Cilium** | CNI and NetworkPolicy controller. Replaces k3s's bundled Flannel. `make cilium-up` runs before `make argocd` on fresh clusters. Enforces ADR-0016 default-deny policies across all always-on namespaces. (ADR-0014) |

### Policy & supply-chain security

| Tool | Role in the platform |
|------|----------------------|
| **Kyverno** | Admission policy engine. Three always-on `ClusterPolicy` objects: (1) validate PSS `restricted` across all namespaces; (2) mutate missing `seccompProfile: RuntimeDefault`; (3) `verifyImages` — audits that images are cosign-signed (currently `Audit`; flip to `Enforce` is a separate ROADMAP item gated on maintainer confirmation). Kyverno also fans out `NetworkPolicy` default-deny overlays via a `kyverno-policies` Application. (ADR-0019) |
| **Trivy Operator** | Continuous CVE scanning + SBOM generation. Watches all pods and produces `VulnerabilityReport` / `SbomReport` CRs; a Grafana dashboard surfaces the findings. `trivy-system-networkpolicy` default-deny overlay. (ADR-0022) |

### Progressive delivery

| Tool | Role in the platform |
|------|----------------------|
| **Argo Rollouts** | Controller that replaces Kubernetes `Deployment` with a `Rollout` for the capstone app. Implements blue/green and Mimir-SLO-gated canary steps via Envoy Gateway traffic-split. `argo-rollouts-networkpolicy` default-deny overlay. (ADR-0020) |

### On-demand (heavy)

| Tool | Role in the platform |
|------|----------------------|
| **TiDB Operator / TiDB cluster** | Distributed, MySQL-compatible database (PD + TiKV + TiDB tiers). On-demand because the operator + cluster consume ~3 GB. `make tidb-operator-up` / `make tidb-up`. |
| **Artifactory OSS** | Artifact and Docker registry. CI pushes signed images here; ArgoCD pulls from here for the capstone app. `make artifactory-up`. (ADR-0011) |
| **Istio ambient mesh** | Zero-sidecar service mesh (istio-base · istio-cni · istiod · ztunnel). `make istio-up`. (ADR-0012) |
| **Kiali** | Service-mesh topology and traffic UI. `make kiali-up`. |
| **Longhorn** | Distributed block storage with UI. `make longhorn-up`. (ADR-0013) |
| **Aiven Inkless** | Diskless Kafka — brokers hold no local state; Garage S3 is the durable layer. `make inkless-up`. (ADR-0015) |
| **Kargo** | GitOps promotion pipeline. A `Warehouse` detects new image digests; a `dev` Stage auto-promotes; a `prod` Stage requires a manual gate. `make kargo-up`. (ADR-0023) |

## The GitOps flow (worth internalising)

1. You change a manifest in `gitops/` and push to **GitLab**.
2. **ArgoCD** notices the commit and compares it to the live cluster.
3. ArgoCD applies the diff — the cluster converges to match git.
4. **You never `kubectl apply` workloads by hand;** git is the only way in.

Terraform/Terragrunt is the exception: it builds the *foundation* that GitOps then runs on. Rule of thumb — **Terraform builds the platform, ArgoCD runs on the platform.**

## The capstone pipeline (learning-path step 6)

The capstone ties every layer together:

```
GitLab CI                                     
  └─ build hello:SHA ─► cosign sign ─► push to Artifactory
                                                │
                                         ArgoCD syncs
                                                │
                                      Envoy Gateway routes
                                       capstone.127.0.0.1.nip.io
                                                │
                               Kyverno verifyImages (admission gate)
                                                │
                            Argo Rollouts canary (Mimir-SLO-gated)
                                                │
                      Grafana dashboard (metrics · logs · traces)
                                                │
                            Vault ExternalSecret (DB/registry creds)
```

On every GitLab CI push a signed `hello:SHA` image lands in Artifactory. ArgoCD updates the capstone `Rollout`; Kyverno's `verifyImages` policy audits signature presence (currently `Audit` mode — enforcement flip is a separate ROADMAP item). Once admitted, Argo Rollouts canaries traffic using Envoy's weighted-backend split, gating on a Mimir success-rate AnalysisTemplate. All activity is observable in Grafana.

## Suggested learning path

0. **Toolchain + Colima** — container runtime VM. Set up first.
1. **Foundation** — `make up` (k3d + ArgoCD + GitLab wiring). The whole lab rebuilds from this one command.
2. **Core platform** — Envoy Gateway routes traffic; Vault + External Secrets manage secrets; Garage + s3manager store objects.
3. **Observability** — Alloy ships telemetry to Mimir (metrics), Loki (logs), Tempo (traces), and Pyroscope (profiles). Grafana displays all four. KSM and node-exporter add cluster and host vitals.
4. **Data layer** — RabbitMQ messages and Valkey key-value, kept busy by data-demo. Real activity means real dashboard data.
5. **Cloud control-plane patterns** — moto mocks AWS; ACK reconciles `Bucket` CRs against it; KRO composes the CRs into a higher-level claim.
6. **Supply-chain security** — GitLab CI signs images with cosign; Kyverno's `verifyImages` ClusterPolicy blocks unsigned images at admission; Trivy Operator continuously scans what's running.
7. **Progressive delivery** — Argo Rollouts replaces the capstone `Deployment` with a canary `Rollout`; Envoy weights traffic; a Mimir AnalysisTemplate gates the canary steps on real SLO data — not timers.
8. **Stateful backup & restore** — Velero schedules back up `data`, `tidb`, `capstone`, and `vault` to Garage S3. `make dr-restore` drives a verified restore drill; `make dr-verify` asserts end-to-end health.
9. **Continuous scanning** — Trivy Operator produces `VulnerabilityReport` and `SbomReport` CRs for every running image; the Lab — Trivy Operator dashboard surfaces CVE findings and SBOM counts.

## Why on-demand for heavy components

A 12 GB Colima VM holds the always-on stack at ~7 GB. Heavy components (TiDB, Artifactory, Istio, Longhorn, Inkless, Kargo) each add 1–4 GB. Running two full stacks at once would exhaust the VM. So heavy components are on-demand — `make <name>-up` / `make <name>-down` — and never registered in `gitops/bootstrap/root-app.yaml`'s auto-synced set. (ADR-0003, ADR-0005)
