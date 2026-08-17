# Lab context & live decisions

A cloud-agnostic learning lab to see how a cloud-native platform fits together:
**Envoy · k3s · ArgoCD · TiDB · Vault · GitLab · Terraform/Terragrunt · Mimir · Loki**
(plus Garage, External Secrets, moto, Grafana, Alloy, kube-state-metrics). This
document describes the **localhost backend** (`local/`) specifically — the default,
free path every `make up` assumes; see [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md)
and [`infra/live/README.md`](../../infra/live/README.md) for the pluggable-backend
picture and the `oracle/` cloud backend.

## Shape
GitOps platform. Terraform/Terragrunt bootstraps a **k3d** (k3s-in-Docker) cluster;
**GitLab** (standalone omnibus container) is the git source of truth; **ArgoCD**
syncs every in-cluster workload from GitLab via an app-of-apps. This shape is
backend-agnostic above the Terraform bootstrap seam (ADR-0026) — only the cluster
creation step differs per backend.

## Hard constraint (localhost backend)
**16 GB M4 Mac.** All components can't run at once. Approach: an always-on light
**core**, with heavy areas brought up one at a time. Runtime is **Colima** (~12 GB VM),
not Docker Desktop.

## Components & where they run
| Component | How / where | Notes |
|---|---|---|
| Cluster | k3d (Terraform/Terragrunt), Traefik off | k3s v1.36.3+k3s1 (pinned, ADR-0030), 2 nodes |
| GitOps engine | ArgoCD (Helm via Terraform = bootstrap) | reads from GitLab |
| Git source | GitLab CE omnibus (docker container) | host `:8929`, cluster `host.k3d.internal:8929` |
| Ingress | Envoy Gateway (Gateway API) | shared Gateway `eg` in `lab-gateway` ns |
| Secrets | Vault (standalone+file PVC) + External Secrets Operator | k8s-auth, role `eso` |
| S3 object store | Garage (`storage` ns, PVC) | buckets: mimir, mimir-ruler, loki |
| Metrics | Alloy (collector) → Mimir (S3=Garage, multi-tenant) → Grafana | tenant `lab` |
| Logs | Alloy (pod logs) → Loki (S3=Garage, multi-tenant) → Grafana | tenant `lab` |
| Traces | producer → Tempo (S3=Garage, multi-tenant) → Grafana | tenant `lab`; OTLP :4317/:4318; needs a producer (an instrumented app) |
| Profiles | Alloy `pyroscope.scrape` (pprof) → Pyroscope (S3=Garage) → Grafana | single-tenant; pprof of Go services |
| Workload health | kube-state-metrics + ArgoCD metrics | drives stack-health dashboard |
| AWS emulation | moto (`moto` ns) | token-free; `S3_IGNORE_SUBDOMAIN_BUCKETNAME=true` (path-style) so ACK works |
| AWS via CRDs | ACK s3-controller (`ack-system`) → moto | creates real buckets; readback limited (see below) |
| Platform API | KRO (`kro` ns) RGD `S3BucketClaim` | one claim → ACK Bucket + catalog ConfigMap |

## Live decisions
- **Ingress vs mesh:** Envoy Gateway = north-south. Service mesh (on-demand, `make mesh-up`) = **Istio ambient + Kiali** (Istio's data plane is Envoy).
- **Observability:** decoupled LGTM — **Alloy → Mimir → Grafana**, never a monolithic single-pod Prometheus (see ADR-0003). Mimir is **multi-tenant** (tenant `lab`; `X-Scope-OrgID` on Alloy remote_write + Grafana datasource). Mimir blocks/ruler on **Garage S3** + a PVC for the ingester WAL (survives restarts; blocks flush every 2h). Dashboards sync from GitLab via Grafana **native Git Sync** (ADR-0006, **adopted**) — Pure Git over an nginx TLS proxy (mkcert) since the lab GitLab is http-only; Grafana 13.0.5 on `kubernetesDashboards`/unified storage. The old k8s-sidecar + ConfigMap delivery is removed; community (gnetId) dashboards stay on a separate file provider. Grafana DB on a PVC (sessions persist). **Logs**: Alloy ships pod logs → **Loki** (single-binary, multi-tenant `auth_enabled` tenant `lab`, Garage-backed `loki` bucket + PVC) → Grafana Loki datasource. Both Mimir & Loki are deployed always-on. **Traces**: **Tempo** (single-binary, multi-tenant tenant `lab`, Garage-backed `tempo` bucket, OTLP receiver :4317/:4318) + Grafana Tempo datasource — verified with a test trace; needs a real producer (an **OTel-instrumented app** — Beyla eBPF was tried then **removed**, it doesn't capture on nested k3d). Grafana dashboards: Lab — Stack Health + Lab — Logs (namespace/pod/search). *Note on the Grafana stack:* Jaeger is a separate project — Tempo is the Grafana-native tracer (ingests Jaeger/OTLP/Zipkin). **Profiles**: **Pyroscope** (chart 2.2.1, single-binary, Garage-backed `pyroscope` bucket via the S3 creds env-chain). **Single-tenant** (the chart exposes no simple multitenancy toggle — the one LGTM**P** component not on tenant `lab`). Producer = **Alloy `pyroscope.scrape`** of Go `/debug/pprof` endpoints (Pyroscope/Mimir/Loki/Tempo) → real flamegraphs, **no eBPF**. Grafana Pyroscope datasource + "Lab — Profiles" dashboard. **LGTMP complete** (Loki+Grafana+Tempo+Mimir+Pyroscope). Dashboards: Lab — Stack Health, Lab — Logs, Lab — Traces, Lab — Profiles. **Metrics scraping** extended beyond ksm+argocd: Alloy also scrapes **node-exporter** + **kubelet/cAdvisor** + each component's `/metrics`, feeding **community dashboards** imported by gnetId (Node Exporter Full, Kubernetes Views, kube-state-metrics, ArgoCD, Loki — folder "Community", datasource Mimir, editable) plus a custom **Lab — Mimir** (`cortex_*`).
- **Object storage:** **Garage**, not MinIO (ADR-0002).
- **AWS emulation:** **moto** (token-free), not LocalStack (2026.x needs an auth token + persistence is Pro-only). moto must run with **`S3_IGNORE_SUBDOMAIN_BUCKETNAME=true`** — otherwise it parses the request Host `moto.moto.svc` as `<bucket>.<domain>` (bucket=`moto`) and 404s every S3 call.
- **AWS via CRDs (ACK) + platform API (KRO):** **ACK** s3-controller (chart 1.10.0, ns `ack-system`) targets moto with `endpoint_use_path_style: true` + `allow_unsafe_aws_endpoint_urls: true`; dummy creds from Vault (`secret/aws/moto`) → ESO INI Secret. **KRO** (0.9.3, ns `kro`) adds a ResourceGraphDefinition `S3BucketClaim` that composes an ACK Bucket + a catalog ConfigMap from one claim. **Verified:** Bucket CRs create real moto buckets; the KRO claim creates both resources. **Known limitation (upstream, documented like Beyla):** ACK S3 `ReadOne` panics (nil deref, `hook.go:460`) because moto's `GetBucketEncryption` returns `…NotFoundError` instead of a default-SSE config (real S3 always returns one; moto `latest` also doesn't), and ACK doesn't nil-check it → the bucket is created but `ACK.ResourceSynced` stays False and reconcile panic-loops (backs off). Not fixable via config; would need patching ACK or moto. ArgoCD reports the app Healthy (no health check for the ACK `Bucket` kind), so the bucket's `ResourceSynced` condition — not ArgoCD green — is the real truth.
- **Secrets:** Vault + ESO. Pattern for any new secret: `vault kv put secret/...` then add an `ExternalSecret` in `gitops/secrets/` — never kubectl-create or commit raw secrets. Vault seals on restart → an interim **auto-unsealer** re-unseals from the `vault-keys` Secret (lab-only). Real KMS auto-unseal would need a cloud KMS / LocalStack Pro — not viable here.
- **Routing:** per-app UIs via Envoy with `*.127.0.0.1.nip.io` hostnames (no /etc/hosts). Grafana=`localhost:8080`, ArgoCD=`argocd.127.0.0.1.nip.io:8080`, Vault=`vault.127.0.0.1.nip.io:8080`, GitLab=`localhost:8929`.
- **TiDB:** MySQL-compatible; demoed with a sample app (`gitops/platform/tidb-demo.yaml`, `make tidb-demo-up`), **not** used as Grafana's backend (would couple always-on Grafana to the heavy on-demand TiDB profile).
- **Longhorn:** on-demand block storage learning objective (ADR-0013, RFC #60). `local-path` remains the provisioner for the always-on stack; Longhorn adds a Kubernetes-native StorageClass + snapshot API + UI as a manual-sync on-demand component. Not auto-synced (12 GB budget). Bring up with `make longhorn-up`.

## Operational rules
1. **No dependency cycle:** never source ArgoCD's git credentials or Vault's unseal key *from Vault* (would cycle ArgoCD↔Vault). Verified acyclic: repo secret is Terraform-made; ESO manages only workload secrets.
2. Plain-manifest pods need a `checksum/config` pod annotation bumped on ConfigMap changes to restart (Helm charts auto-roll).
3. Shell is **zsh** (unquoted `$var` does not word-split).
4. `.gitignore` uses root-anchored `/secrets/` so `gitops/secrets/` (ExternalSecret manifests, not real secrets) commits.

## From-scratch / DR
See [../DR.md](../DR.md) for the exact bootstrap order and `make up` automation.
