# k8s-anywhere

*(renamed from `k8s-lab` 2026-07-13 to match the cloud-agnostic goal below)*

A **cloud-agnostic GitOps platform** that wires a full cloud-native stack together as
portable infrastructure-as-code — so you can see how the pieces actually fit, not learn
them in isolation. The identical `gitops/` state deploys to a free **localhost** cluster
(the default: one 16 GB Mac, zero external dependencies) or to any CNCF-conformant
**cloud** Kubernetes backend, chosen by swapping the Terraform/Terragrunt bootstrap
module — never by forking the GitOps layer. See
[ADR-0026](docs/decisions/adr-0026-cloud-agnostic-infrastructure.md). GitLab holds the
manifests, and **ArgoCD continuously syncs everything else in**, identically regardless
of where the cluster runs.

The sections below (Quick start, Endpoints, DR) describe the **localhost backend**,
which is built today and remains the default. A second backend module targeting
Oracle Cloud's Always Free tier is also built and partially verified against a real
account — see [`infra/live/README.md`](infra/live/README.md) → Status for exactly
what has and hasn't run end-to-end yet.

Built as code end to end: **one command (`make up`) rebuilds the whole lab from
scratch**, with self-verifying **disaster-recovery** and **zero-downtime blue/green**
drills to prove recovery actually works.

- 📊 **[docs/dependency-tree.md](docs/dependency-tree.md)** — full dependency & integration graph (who deploys / depends on / talks to whom)
- 🛟 **[docs/DR.md](docs/DR.md)** — recovery model + the day-0 bootstrap chain
- 📐 **[docs/00-architecture.md](docs/00-architecture.md)** — roles & learning path · 🧭 **[docs/decisions/](docs/decisions/)** — ADRs

## The stack

Everything except Terraform/Terragrunt, GitLab, and the front door runs **in** the
cluster, deployed by ArgoCD (one `Application` per component).

| Layer | Tools |
|-------|-------|
| **Bootstrap (IaC)** | Terraform · Terragrunt · k3d (k3s-in-Docker) |
| **GitOps** | GitLab (git source, omnibus container) · ArgoCD (engine, app-of-apps) |
| **Ingress** | Envoy Gateway (north-south, Gateway API · `envoy-gateway-system-networkpolicy` default-deny overlay; ADR-0008, ADR-0016) |
| **Secrets** | Vault (KV v2) · External Secrets Operator |
| **Storage** | Garage (S3-compatible) · s3manager (bucket browser) |
| **Backup & restore** | Velero (cluster + PVC backups to Garage S3 · Kopia uploader · `velero-schedules` daily Schedules for data / tidb / capstone / vault · `velero-networkpolicy` default-deny overlay; ADR-0021) |
| **Observability (LGTMP)** | Alloy · Mimir (metrics) · Loki (logs) · Tempo (traces) · Pyroscope (profiles) · Grafana · kube-state-metrics · node-exporter |
| **Data layer** | RabbitMQ (message broker + management UI) · Valkey (cache / key-value) · redis_exporter · data-demo (traffic generator) |
| **Cloud / platform-eng** | moto (AWS mock) · ACK (AWS Controllers for K8s → moto) · KRO (Kube Resource Orchestrator) |
| **CNI (bootstrap)** | Cilium (`make cilium-up` — run before `make argocd` on fresh clusters; ADR-0014) |
| **Policy & supply chain** | Kyverno (NetworkPolicy default-deny fan-out · `kyverno-policies` ClusterPolicies: PSS-restricted validate + seccomp mutate + verifyImages; ADR-0016, ADR-0019) · Trivy Operator (`trivy-system-networkpolicy` default-deny overlay; continuous CVE scanning + SBOM generation; ADR-0022) · `governance` ApplicationSet (per-namespace LimitRange resource defaults fan-out; RFC #293) |
| **TLS / certificates** | cert-manager (`cert-manager-root-ca` self-signed root CA bootstrap chain — `selfsigned-bootstrap` → root `Certificate` → `k8s-lab-ca` `ClusterIssuer` · `lab-gateway-certificate` wildcard `*.127.0.0.1.nip.io` Certificate terminating the shared Gateway's `https`/443 listener, alongside the original `http`/80 one · DR front door proxies `:8443` through as a TCP passthrough · `cert-manager-networkpolicy` default-deny overlay; ADR-0028) |
| **Progressive delivery** | Argo Rollouts (`argo-rollouts` controller + `capstone-rollout` AnalysisTemplate — Mimir SLO-gated canary steps via Envoy Gateway traffic-split · `argo-rollouts-networkpolicy` default-deny overlay; ADR-0020) |
| **Autoscaling** | KEDA (event-driven autoscaling — 60+ built-in scalers including RabbitMQ queue depth and Prometheus expressions, augments the stock HPA · `data-demo-keda-scaling` `ScaledObject` demo scaling `rabbitmq-load` 1→5 replicas on the `demo` queue's real depth via the RabbitMQ management API · `keda-networkpolicy` default-deny overlay; ADR-0029) |
| **Promotion pipelines** | Kargo (`make kargo-up` / `make kargo-down` — Warehouse detects new image digests → Stage dev auto-promote → Stage prod manual gate · `kargo-project` capstone-pipeline Project · `kargo-networkpolicy` default-deny overlay · `kargo-project-networkpolicy` capstone-pipeline NetworkPolicy overlay; ADR-0023) |
| **On-demand (heavy)** | TiDB Operator (`make tidb-operator-up` / `make tidb-operator-down`) · TiDB cluster (`make tidb-up` / `make tidb-down`) · TiDB demo app (`make tidb-demo-up` / `make tidb-demo-down`) · Artifactory OSS (`make artifactory-up` / `make artifactory-down`) · Harbor CNCF OCI registry (`make harbor-up` / `make harbor-down` — Garage S3 backend; ADR-0024) · Istio ambient mesh — istio-base · istio-cni · istiod · ztunnel (`make istio-up` / `make istio-down`) · Kiali service mesh UI (`make kiali-up` / `make kiali-down`) · Combined mesh (`make mesh-up` / `make mesh-down`) · Longhorn distributed block storage (`make longhorn-up` / `make longhorn-down`) · Aiven Inkless diskless Kafka (`make inkless-up` / `make inkless-down`) · Kargo promotion engine (`make kargo-up` / `make kargo-down`) |

## Prerequisites

macOS with **Colima** (not Docker Desktop). Install the toolchain, then verify:

```sh
brew install colima docker k3d kubectl helm terraform terragrunt kustomize argocd vault yq jq mkcert
make preflight      # checks all of the above are on PATH
```

## Quick start — one command

```sh
make up             # bootstrap the ENTIRE lab from scratch, in order (~10 min; GitLab's first boot dominates)
make status         # VM RAM + per-namespace usage + any unhealthy pods
make dr-verify      # assert the whole lab is healthy end-to-end (real checks)
```

`make up` runs the only imperative (day-0) steps — Colima → k3d → ArgoCD → GitLab →
app-of-apps → Vault/Garage bootstrap — then ArgoCD reconciles everything else. The
ordered chain is documented in [docs/DR.md](docs/DR.md). Run `make` with no target
for the full command list.

### Apply Grafana dashboard changes (localhost lab)

Lab dashboards (`grafana/dashboards/*.json`) are managed by Grafana
native Git Sync (Pure Git), not a k8s sidecar. Current dashboards:
`Lab — Argo Rollouts (Progressive Delivery)` · `Lab — ArgoCD (GitOps)` · `Lab — Capstone` ·
`Lab — Cloud Control Plane (moto / ACK / KRO)` · `Lab — Envoy Gateway (Ingress)` ·
`Lab — Garage S3 (Object Storage)` · `Lab — Git Sync` · `Lab — Grafana` ·
`Lab — Inkless (Diskless Kafka)` · `Lab — Kyverno (Admission Policy)` · `Lab — Logs` ·
`Lab — Mimir` · `Lab — Profiles` · `Lab — RabbitMQ` · `Lab — Stack Health` ·
`Lab — TiDB Demo App` · `Lab — Traces` · `Lab — Trivy Operator (Supply Chain)` ·
`Lab — Valkey` · `Lab — Vault & Secrets` · `Lab — Velero (Backup & Restore)`.
After editing them, run:

```sh
make gitlab-push                # push dashboard JSON changes to the lab's GitOps source
make gitlab-tls-bootstrap       # ensure the GitLab HTTPS proxy + CA config are in place
make grafana-gitsync-bootstrap  # ensure Grafana's "Lab dashboards (GitLab, Pure Git)" repo exists
```

If the local GitLab `main` branch has diverged and you want to overwrite it, run
`make gitlab-force-push` instead. Grafana polls the Git Sync repo every 60s and
applies updates automatically.

## Endpoints

After `make up`, UIs are served via the stable front door on **`:8000`**
(hostnames resolve to 127.0.0.1 via `nip.io` — no `/etc/hosts` edits):

| UI | URL |
|----|-----|
| ArgoCD | http://argocd.127.0.0.1.nip.io:8000 |
| Grafana | http://localhost:8000 |
| Vault | http://vault.127.0.0.1.nip.io:8000 |
| S3 browser | http://s3.127.0.0.1.nip.io:8000 |
| moto (AWS mock) | http://moto.127.0.0.1.nip.io:8000/moto-api/ |
| RabbitMQ | http://rabbitmq.127.0.0.1.nip.io:8000 |
| Argo Rollouts | http://rollouts.127.0.0.1.nip.io:8000 |
| Capstone *(demo app)* | http://capstone.127.0.0.1.nip.io:8000 |
| GitLab | http://localhost:8929 |
| Artifactory *(on-demand)* | http://artifactory.127.0.0.1.nip.io:8000 |
| Kiali *(on-demand)* | http://kiali.127.0.0.1.nip.io:8000 |
| Longhorn *(on-demand)* | http://longhorn.127.0.0.1.nip.io:8000 |
| Kargo *(on-demand)* | http://kargo.127.0.0.1.nip.io:8000 |

`make argocd-password` prints the ArgoCD admin password. `:8080` is a per-cluster
Envoy LB port used underneath the front door and is not the canonical UI entrypoint.

## Disaster recovery & blue/green

The lab is **recreate-from-code**, and recovery is *exercised*, not assumed:

| Command | What it does |
|---------|--------------|
| `make dr-verify` | Real end-to-end health check: nodes, every ArgoCD app Synced+Healthy, Vault unsealed, all ExternalSecrets synced, Garage + buckets, a **live Mimir query**, Grafana. Safe anytime. |
| `make dr-test` | Full DR drill: **destroy** the lab → `make up` → verify. `SCOPE=cluster\|full\|machine`. |
| `make dr-bluegreen` | **Zero-downtime** DR: stand up a 2nd (green) cluster, cut over via the front-door proxy, prove ~100% uptime with a continuous probe. |
| `make dr-bluegreen-promote` | Migrate to green as a full stack and **retire blue** — serving never drops. |

See [docs/DR.md](docs/DR.md) and [ADR-0005](docs/decisions/adr-0005-spof-recreate-over-ha.md)
(why true HA isn't possible on a single host, and what the lab does instead).

## Quality gates

`dr-verify`/`dr-test` are the *top* of the pyramid — they need a live 16 GB lab. The
*bottom* is fast, clusterless, and runs on every push via GitHub Actions (and locally):

| Command | What it checks |
|---------|----------------|
| `make lint` | `shellcheck` every script + `yamllint` the manifests/IaC |
| `make validate` | schema-validate gitops manifests (`kubeconform`) + Terraform (`fmt`/`validate`/`tflint`) |
| `make test` | `bats` unit tests: probe uptime math, destructive-script guards, the drift detectors |
| `make readme-check` · `make lab-ui-check` | docs/dashboard drift detectors |
| `make ci` | all of the above in one shot (mirrors the CI workflow) |

Tools are optional locally (skipped with a note, like `make preflight`); CI installs
them and enforces every gate.

## The 16 GB reality

The always-on stack above fits the 12 GB Colima VM (~7 GB used). Adding a **heavy**
profile (TiDB, Artifactory, Istio mesh, Longhorn) needs care, and two *full* stacks
don't fit at once — proven by the blue/green drill, which is why its promote retires
blue *before* growing green. GitLab runs as a standalone container (off the cluster
budget; `make gitlab-down` frees ~3 GB).

## Layout

- `infra/` — Terraform modules + Terragrunt live config (the day-0 bootstrap)
- `gitops/` — what ArgoCD syncs: `bootstrap/` (root app-of-apps) → `platform/` (one
  `Application` per component) → `network/ vault/ secrets/ storage/ observability/
  moto/ ack/ kro/ apps/`; `bluegreen/` (green's serving-tier app-of-apps)
- `gitlab/` — GitLab omnibus docker-compose · `.gitlab-ci.yml` — capstone build pipeline (builds `gitops/apps/demo/` → pushes to Artifactory; see [docs/dependency-tree.md](docs/dependency-tree.md))
- `scripts/` — bootstrap + DR/blue-green scripts + the quality gates (`lint.sh`, `validate-*.sh`, `test.sh`)
- `tests/` — `bats` unit tests + fixtures · `.github/workflows/ci.yml` — the clusterless CI gates · `docs/` — architecture, DR, decisions, dependency tree

## Repo

`main` lives in the local **GitLab** (the GitOps source ArgoCD reads from) and is
mirrored to **GitHub**
([github.com/tooming/k8s-anywhere](https://github.com/tooming/k8s-anywhere)).
Push to GitLab for the running lab to pick up changes; GitHub is the public copy.
