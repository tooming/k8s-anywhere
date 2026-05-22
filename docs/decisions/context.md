# Lab context & live decisions

A localhost learning lab to see how a cloud-native platform fits together:
**Envoy · k3s · ArgoCD · TiDB · Vault · GitLab · Terraform/Terragrunt · Mimir · Loki**
(plus Garage, External Secrets, moto, Grafana, Alloy, kube-state-metrics).

## Shape
GitOps platform. Terraform/Terragrunt bootstraps a **k3d** (k3s-in-Docker) cluster;
**GitLab** (standalone omnibus container) is the git source of truth; **ArgoCD**
syncs every in-cluster workload from GitLab via an app-of-apps.

## Hard constraint
**16 GB M4 Mac.** All components can't run at once. Approach: an always-on light
**core**, with heavy areas brought up one at a time. Runtime is **Colima** (~12 GB VM),
not Docker Desktop.

## Components & where they run
| Component | How / where | Notes |
|---|---|---|
| Cluster | k3d (Terraform/Terragrunt), Traefik off | k3s v1.33.6, 2 nodes |
| GitOps engine | ArgoCD (Helm via Terraform = bootstrap) | reads from GitLab |
| Git source | GitLab CE omnibus (docker container) | host `:8929`, cluster `host.k3d.internal:8929` |
| Ingress | Envoy Gateway (Gateway API) | shared Gateway `eg` in `lab-gateway` ns |
| Secrets | Vault (standalone+file PVC) + External Secrets Operator | k8s-auth, role `eso` |
| S3 object store | Garage (`storage` ns, PVC) | buckets: mimir, mimir-ruler, loki |
| Metrics | Alloy (collector) → Mimir (S3=Garage, multi-tenant) → Grafana | tenant `lab` |
| Logs | Alloy (pod logs) → Loki (S3=Garage, multi-tenant) → Grafana | tenant `lab` |
| Workload health | kube-state-metrics + ArgoCD metrics | drives stack-health dashboard |
| AWS emulation | moto (`moto` ns) | token-free; ACK targets it |

## Live decisions
- **Ingress vs mesh:** Envoy Gateway = north-south. Service mesh (planned) = **Istio ambient + Kiali** (Istio's data plane is Envoy).
- **Observability:** decoupled LGTM — **Alloy → Mimir → Grafana**, never a monolithic single-pod Prometheus (see ADR-0003). Mimir is **multi-tenant** (tenant `lab`; `X-Scope-OrgID` on Alloy remote_write + Grafana datasource). Mimir blocks/ruler on **Garage S3** + a PVC for the ingester WAL (survives restarts; blocks flush every 2h). Dashboards are git-synced via the Grafana sidecar + labelled ConfigMaps. Grafana DB on a PVC (sessions persist). **Logs**: Alloy ships pod logs → **Loki** (single-binary, multi-tenant `auth_enabled` tenant `lab`, Garage-backed `loki` bucket + PVC) → Grafana Loki datasource. Both Mimir & Loki are deployed always-on.
- **Object storage:** **Garage**, not MinIO (ADR-0002).
- **AWS emulation:** **moto** (token-free), not LocalStack (2026.x needs an auth token + persistence is Pro-only). ACK will target moto.
- **Secrets:** Vault + ESO. Pattern for any new secret: `vault kv put secret/...` then add an `ExternalSecret` in `gitops/secrets/` — never kubectl-create or commit raw secrets. Vault seals on restart → an interim **auto-unsealer** re-unseals from the `vault-keys` Secret (lab-only). Real KMS auto-unseal would need a cloud KMS / LocalStack Pro — not viable here.
- **Routing:** per-app UIs via Envoy with `*.127.0.0.1.nip.io` hostnames (no /etc/hosts). Grafana=`localhost:8080`, ArgoCD=`argocd.127.0.0.1.nip.io:8080`, Vault=`vault.127.0.0.1.nip.io:8080`, GitLab=`localhost:8929`.
- **TiDB:** MySQL-compatible; will be demoed with a sample app, **not** used as Grafana's backend (would couple always-on Grafana to the heavy on-demand TiDB profile).
- **Longhorn:** not needed — `local-path` covers PVCs; optional learning extra, fiddliest on k3d. Deferred.

## Operational rules
1. **No dependency cycle:** never source ArgoCD's git credentials or Vault's unseal key *from Vault* (would cycle ArgoCD↔Vault). Verified acyclic: repo secret is Terraform-made; ESO manages only workload secrets.
2. Plain-manifest pods need a `checksum/config` pod annotation bumped on ConfigMap changes to restart (Helm charts auto-roll).
3. Shell is **zsh** (unquoted `$var` does not word-split).
4. `.gitignore` uses root-anchored `/secrets/` so `gitops/secrets/` (ExternalSecret manifests, not real secrets) commits.

## From-scratch / DR
See [../DR.md](../DR.md) for the exact bootstrap order and `make up` automation.
