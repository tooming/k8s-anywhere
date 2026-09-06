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
│  INGRESS      Traefik        (bundled with k3s; north-south traffic)       │
│  TLS          cert-manager  (auto-renewed certs from a self-signed CA)    │
│  SECRETS      Vault  ──►  External Secrets Operator  ──►  k8s Secrets     │
│  CNI / POLICY Cilium  (NetworkPolicy enforcement; default-deny per ns)     │
│  POLICY       Kyverno  (admission validation · mutation · verifyImages)    │
│  STORAGE      Garage (S3)  ──►  s3manager (bucket browser UI)             │
│  BACKUP       Velero  (cluster + PVC snapshots → Garage S3)               │
│  DATA         RabbitMQ  ·  Valkey (cache/KV)  ·  data-demo (generator)   │
│  AUTOSCALE    KEDA  (scales rabbitmq-load on real RabbitMQ queue depth)  │
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
│  Harbor (OCI artifact + Docker registry; ADR-0024)                        │
│  Istio ambient mesh (istio-base · istio-cni · istiod · ztunnel) · Kiali  │
│  Longhorn (distributed block storage)                                      │
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
| **GitLab** | Git source of truth. Hosts the `gitops/` manifests and runs the CI pipeline (build → cosign sign → push to Harbor per ADR-0024). |
| **ArgoCD** | GitOps engine. Watches GitLab and makes the cluster match it (app-of-apps pattern). All workloads below arrive via ArgoCD, never by `helm install` or `kubectl apply`. |

> **GitLab vs. Forgejo, as of 2026-08-17.** This table describes what a fresh `make up`
> still literally does — bootstrap GitLab as the git source (ADR-0035's migration items
> 3/4 not yet picked up). The already-running lab was separately re-pointed at Forgejo
> directly on the live cluster (PR #1205), so today's steady-state git source is Forgejo,
> not GitLab. See [docs/dependency-tree.md](dependency-tree.md)'s "Day-0 bootstrap chain"
> section for the full explanation of this gap and its own tracking note.

### Ingress

| Tool | Role in the platform |
|------|----------------------|
| **Traefik** | North-south ingress, bundled with k3s. External traffic enters via Traefik's own `IngressRoute` CRD; Traefik routes it to in-cluster Services. Per-app `allow-*-from-gateway` NetworkPolicy rules (sourced from kube-system) apply ADR-0016. (ADR-0040) |

### TLS / certificates

| Tool | Role in the platform |
|------|----------------------|
| **cert-manager** | Automated TLS certificate lifecycle — issues and auto-renews certs from a self-signed root CA (`k8s-lab-ca`) at the Gateway edge, backing a wildcard `*.127.0.0.1.nip.io` Certificate. Every north-south route is reachable over both HTTP and the shared Gateway's HTTPS listener (:8443); this is additive alongside the original HTTP-only path, never a breaking cutover. `restricted` PSA, zero carve-out. (ADR-0028) |

### Secrets

| Tool | Role in the platform |
|------|----------------------|
| **Vault** | Secrets management (KV v2). Holds DB passwords, tokens, registry credentials, and the cosign private key. |
| **External Secrets Operator** | Bridges Vault to Kubernetes. A `ClusterSecretStore` points to Vault; `ExternalSecret` objects pull values into native k8s `Secret`s without embedding secrets in git. |

### Storage

| Tool | Role in the platform |
|------|----------------------|
| **Garage** | S3-compatible object store running in-cluster. Buckets: `mimir`, `mimir-ruler`, `loki`, `tempo`, `pyroscope`. Also the Velero backup target and Terraform-state backend. (ADR-0002, ADR-0007) |
| **s3manager** | Read-only web UI for browsing Garage buckets — visible on the Traefik front door. |

### Backup & restore

| Tool | Role in the platform |
|------|----------------------|
| **Velero** | Cluster resource + PVC backup/restore to Garage S3. Daily `Schedule` objects back up the `data`, `tidb`, `capstone`, `vault`, and `observability` namespaces with the Kopia uploader. `make dr-restore` drives a verified restore drill. `velero-networkpolicy` default-deny overlay. (ADR-0021) |

### Observability (LGTMP)

| Tool | Role in the platform |
|------|----------------------|
| **Alloy** | OpenTelemetry-compatible telemetry collector. Scrapes Prometheus metrics from every workload (static targets for Kyverno, ESO, Argo Rollouts, Alloy self-metrics, KSM, node-exporter; dynamic scrape for pods); ships logs via Loki, traces via Tempo, profiles via Pyroscope. |
| **Mimir** | Long-term, horizontally-scalable metrics storage (Prometheus-compatible). All Grafana dashboards query Mimir with `X-Scope-OrgID: lab`. |
| **Loki** | Log aggregation. Alloy ships pod stdout/stderr logs here. |
| **Tempo** | Distributed tracing. OTLP-compatible ingest. |
| **Pyroscope** | Continuous profiling. |
| **Grafana** | Single pane of glass over Mimir, Loki, Tempo, and Pyroscope. Dashboards are managed via native Git Sync (ADR-0006) — no sidecar required. 32 lab dashboards (`grafana/dashboards/*.json`) cover every always-on component and the capstone pipeline — 38 dashboard files total, minus the 6 tied to on-demand/heavy components (Harbor, Istio, Kargo, Longhorn, TiDB ×2). |
| **kube-state-metrics** | Exports Kubernetes resource state (pod phase, deployment replicas, PVC status, node readiness) as Prometheus metrics. |
| **node-exporter** | Exports host-level metrics (CPU, memory, disk, network) from the Colima VM. |

### Data layer

| Tool | Role in the platform |
|------|----------------------|
| **RabbitMQ** | Message broker with management UI. (ADR-0009) |
| **Valkey** | In-memory cache / key-value store; drop-in Redis replacement. (ADR-0018) |
| **data-demo** | Traffic generator that publishes messages to RabbitMQ and reads/writes Valkey — keeps the data-layer dashboards alive with real activity. |

### Autoscaling

| Tool | Role in the platform |
|------|----------------------|
| **KEDA** | Event-driven autoscaling — scales a workload on a real signal (a RabbitMQ queue's depth, a Prometheus expression), augmenting the stock HPA rather than replacing it. A `ScaledObject` demo (`gitops/data/demo/keda-scaling/`) scales the `rabbitmq-load` Deployment on the `data` namespace's RabbitMQ queue depth. Its admission webhook's TLS is wired to cert-manager's `k8s-lab-ca` — a second real consumer beyond the Gateway. `restricted` PSA, zero carve-out. On-demand as of 2026-08-25 (`make keda-up` / `make keda-down`, cluster-load reduction — was always-on before). (ADR-0029) |

### Cloud / platform-engineering

| Tool | Role in the platform |
|------|----------------------|
| **moto** | AWS API mock (S3, IAM, STS). ACK targets it instead of real AWS — no cloud account needed. |
| **ACK (S3 controller)** | AWS Controllers for Kubernetes. Reconciles `Bucket` CRs against the moto mock. |
| **KRO** | Kube Resource Orchestrator. Defines a `ResourceGraphDefinition` that turns a single `S3BucketClaim` CR into a coordinated set of ACK `Bucket` resources — a minimal platform-engineering composition layer. Controller suspended 2026-08-25 for cluster-load reduction (chronic crash-loop under this host's apiserver latency); its namespace/RBAC scaffolding stays auto-synced, re-enable by restoring `gitops/platform/kro.yaml`'s `automated` sync block. |

### CNI (bootstrap step)

| Tool | Role in the platform |
|------|----------------------|
| **Cilium** | CNI and NetworkPolicy controller. Replaces k3s's bundled Flannel. `make cilium-up` runs before `make argocd` on fresh clusters. Enforces ADR-0016 default-deny policies across all always-on namespaces. (ADR-0014) |

### Policy & supply-chain security

| Tool | Role in the platform |
|------|----------------------|
| **Kyverno** | Admission policy engine. Three always-on `ClusterPolicy` objects: (1) validate PSS `restricted` across all namespaces; (2) mutate missing `seccompProfile: RuntimeDefault`; (3) `verifyImages` — blocks admission of any image that isn't cosign-signed (`Enforce` mode since 2026-08-18, CHARTER Objective O4 — see [docs/done/2026-08-18-cosign-enforce-flip.md](done/2026-08-18-cosign-enforce-flip.md)). Kyverno also fans out `NetworkPolicy` default-deny overlays via a `kyverno-policies` Application. (ADR-0019) |
| **Trivy Operator** | Continuous CVE scanning + SBOM generation. Watches all pods and produces `VulnerabilityReport` / `SbomReport` CRs; a Grafana dashboard surfaces the findings. `trivy-system-networkpolicy` default-deny overlay. (ADR-0022) |

### Progressive delivery

| Tool | Role in the platform |
|------|----------------------|
| **Argo Rollouts** | Controller that replaces Kubernetes `Deployment` with a `Rollout` for the capstone app. Implements blue/green and Mimir-SLO-gated canary steps via Traefik's built-in traffic-split. `argo-rollouts-networkpolicy` default-deny overlay. (ADR-0020) |

### On-demand (heavy)

| Tool | Role in the platform |
|------|----------------------|
| **TiDB Operator / TiDB cluster** | Distributed, MySQL-compatible database (PD + TiKV + TiDB tiers). On-demand because the operator + cluster consume ~3 GB. `make tidb-operator-up` / `make tidb-up`. |
| **Harbor** | OCI artifact and Docker registry (CNCF graduated; Go runtime, no JVM). Registry storage backed by Garage S3. `make harbor-up` / `make harbor-down`. (ADR-0024; supersedes ADR-0011 — Artifactory OSS fully decommissioned) |
| **Istio ambient mesh** | Zero-sidecar service mesh (istio-base · istio-cni · istiod · ztunnel). `make istio-up`. (ADR-0012) |
| **Kiali** | Service-mesh topology and traffic UI. `make kiali-up`. |
| **Longhorn** | Distributed block storage with UI. `make longhorn-up`. (ADR-0013) |
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
  └─ build library/hello:SHA ─► cosign sign ─► push to Harbor (ADR-0024)
                                                │
                                         ArgoCD syncs
                                                │
                                      Traefik routes
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

On every GitLab CI push a signed `library/hello:SHA` image lands in Harbor (`harbor.127.0.0.1.nip.io`, `make harbor-up`; per ADR-0024). ArgoCD updates the capstone `Rollout`; Kyverno's `verifyImages` policy blocks admission of any unsigned image (`Enforce` mode since 2026-08-18, CHARTER Objective O4). Once admitted, Argo Rollouts canaries traffic using Traefik's weighted-backend split, gating on a Mimir success-rate AnalysisTemplate. All activity is observable in Grafana.

## Suggested learning path

0. **Toolchain + Colima** — container runtime VM. Set up first.
1. **Foundation** — `make up` (k3d + ArgoCD + GitLab wiring — see the "GitOps engine" table above for why this still says GitLab, not Forgejo). The whole lab rebuilds from this one command.
2. **Core platform** — Traefik routes traffic; cert-manager issues and auto-renews the TLS certs Traefik's TLSStore serves from a self-signed root CA; Vault + External Secrets manage secrets; Garage + s3manager store objects.
3. **Observability** — Alloy ships telemetry to Mimir (metrics), Loki (logs), Tempo (traces), and Pyroscope (profiles). Grafana displays all four. KSM and node-exporter add cluster and host vitals.
4. **Data layer** — RabbitMQ messages and Valkey key-value, kept busy by data-demo. Real activity means real dashboard data. KEDA scales the `rabbitmq-load` Deployment on the queue's real depth — event-driven autoscaling, not a timer or a hand-set replica count.
5. **Cloud control-plane patterns** — moto mocks AWS; ACK reconciles `Bucket` CRs against it; KRO composes the CRs into a higher-level claim.
6. **Supply-chain security** — GitLab CI signs images with cosign; Kyverno's `verifyImages` ClusterPolicy blocks unsigned images at admission; Trivy Operator continuously scans what's running.
7. **Progressive delivery** — Argo Rollouts replaces the capstone `Deployment` with a canary `Rollout`; Traefik weights traffic; a Mimir AnalysisTemplate gates the canary steps on real SLO data — not timers.
8. **Stateful backup & restore** — Velero schedules back up `data`, `tidb`, `capstone`, `vault`, and `observability` to Garage S3. `make dr-restore` drives a verified restore drill; `make dr-verify` asserts end-to-end health.
9. **Continuous scanning** — Trivy Operator produces `VulnerabilityReport` and `SbomReport` CRs for every running image; the Lab — Trivy Operator dashboard surfaces CVE findings and SBOM counts.
10. **DR / blue-green** — `make dr-bluegreen` stands up a second k3d "green" cluster that sources the *same* `gitops/` repo via `gitops/bluegreen/green-root.yaml`, cuts Traefik traffic over to green, and verifies service continuity before retiring blue with `make dr-bluegreen-promote`; `make dr-bluegreen-down` reclaims green's RAM once the exercise is done (see [docs/DR.md §Zero-downtime blue/green](DR.md) for the full runbook). Steps 8 and 10 test two distinct recovery modes: Velero restores data from backup *on the same cluster*; blue-green rebuilds the whole platform on a *fresh* cluster with live traffic cut over — proving the "recreate-from-code" CHARTER Core Value under real traffic, not just a data restore.
11. **GitOps promotion pipelines** — Kargo's `Warehouse` CRD watches Harbor for new image digests pushed by GitLab CI; a `dev` `Stage` auto-promotes; a `prod` `Stage` requires a manual gate approval in the Kargo UI (`kargo.127.0.0.1.nip.io`, `make kargo-up` / `make kargo-down` when done). Promotion history is visible in the Lab — Kargo dashboard (`lab-kargo.json`). See [ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md). This layer adds *multi-stage, Warehouse-gated* promotion on top of the Argo Rollouts canary at step 7 — the two complement each other: Argo Rollouts controls in-cluster traffic shaping during a release; Kargo controls which image digest gets promoted across environment stages in the first place.
12. **Cloud-agnostic infrastructure design** — read [`infra/live/README.md`](../infra/live/README.md): the `argocd`/`gitlab` Terragrunt units depend only on the `cluster` unit's `kube_context`/`cluster_name`/`api_endpoint` outputs, never on which backend produced them, which is why steps 1–11 above run identically whether `cluster/` is `local/` (k3d, this lab's default) or `oracle/` (Oracle Cloud Always Free + k3s, see [ADR-0026](decisions/adr-0026-cloud-agnostic-infrastructure.md) and [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md)). The lesson: portability is a property of *where the Terraform bootstrap seam sits*, not something bolted on afterward — GitOps state in `gitops/` never needs to know or care where the cluster runs.

## Why on-demand for heavy components

A 12 GB Colima VM holds the always-on stack at ~7 GB. Heavy components (TiDB, Harbor, Istio, Longhorn, Kargo) each add 1–4 GB. Running two full stacks at once would exhaust the VM. So heavy components are on-demand — `make <name>-up` / `make <name>-down` — and never registered in `gitops/bootstrap/root-app.yaml`'s auto-synced set. (ADR-0003, ADR-0005)

**This budget is mechanically enforced, not just documented** (2026-08-05 incident: several
unrelated live-debugging sessions each ran a `make <name>-up` and never the matching
`-down`, so Harbor + Istio + Kiali + Longhorn + Kargo + TiDB ended up running
simultaneously — plus a fully orphaned `artifactory` namespace with no owning ArgoCD
Application, left over from before ADR-0024 decommissioned it. The VM hit its memory
ceiling, the apiserver started timing out, envoy-gateway lost leader election and
crashlooped, and every front-door UI in the table above 502'd). `scripts/ondemand-budget-check.sh`
(`make ondemand-budget-check`) reports which on-demand units are currently live and flags
orphaned on-demand namespaces; every `<name>-up` target calls it as a blocking pre-flight
(override: `ONDEMAND_BUDGET_FORCE=1`) so bringing a second heavy unit up without tearing
the first one down fails fast instead of silently degrading the whole lab hours or days
later. `make health` also prints its report (informational — on-demand load never flips
`make health`'s pass/fail, matching the always-on-only contract above), so a stray
component shows up on the very next health check even outside a fresh `-up` attempt.
