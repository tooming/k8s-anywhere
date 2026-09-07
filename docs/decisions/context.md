# Lab context & live decisions

A cloud-agnostic learning lab to see how a cloud-native platform fits together:
**Traefik · k3s · ArgoCD · cert-manager · Terraform/Terragrunt**. A large,
deliberate simplification round (2026-09-06/2026-09-07) removed everything else
this lab used to run — Harbor, Vault, GitLab/Forgejo, Garage, External Secrets
Operator, and more — entirely, no replacement; see CHARTER.md's "The 2026-09-07
simplification" and each removed component's own ADR Status. This document
describes the **localhost backend** (`local/`) specifically — the default, free
path every `make up` assumes; see
[ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) and
[`infra/live/README.md`](../../infra/live/README.md) for the pluggable-backend
picture and the `oracle/` cloud backend.

## Shape
GitOps platform. Terraform/Terragrunt bootstraps a **k3d** (k3s-in-Docker) cluster;
**GitHub** (this repo's own public remote) is the git source of truth; **ArgoCD**
syncs every in-cluster workload from GitHub via an app-of-apps. This shape is
backend-agnostic above the Terraform bootstrap seam (ADR-0026) — only the cluster
creation step differs per backend.

## Hard constraint (localhost backend)
**16 GB M4 Mac.** All components can't run at once. Approach: an always-on light
**core**, with heavy areas brought up one at a time. Runtime is **Colima** (~12 GB VM),
not Docker Desktop.

## Components & where they run
| Component | How / where | Notes |
|---|---|---|
| Cluster | k3d (Terraform/Terragrunt), Traefik bundled (ADR-0040) | k3s v1.36.4+k3s1 (pinned, ADR-0030), 2 nodes |
| GitOps engine | ArgoCD (Helm via Terraform = bootstrap) | reads from this repo's public GitHub remote |
| Git source | GitHub (this repo's own public remote) | `main` branch, no self-hosted git any more |
| Ingress | Traefik (bundled with k3s) | `IngressRoute` CRD; shared `TLSStore` in `lab-gateway` ns |
| TLS / certificates | cert-manager (self-signed root CA chain, ADR-0028) | `k8s-lab-ca` `ClusterIssuer`; wildcard `*.127.0.0.1.nip.io` Certificate |

## Live decisions
- **Ingress vs mesh:** Traefik = north-south (ADR-0040). The service-mesh learning objective (on-demand Istio ambient + Kiali, ADR-0012) was **removed 2026-09-06** (maintainer decision, no replacement) — see ADR-0012's Status for the full removal note.
- **Observability REMOVED 2026-09-06 (ADR-0041, supersedes ADR-0006 + ADR-0034):** the entire LGTM(P) stack (Alloy, Mimir, Loki, Tempo, Pyroscope), Grafana, kube-state-metrics, and node-exporter were removed as workloads with no replacement, per explicit maintainer direction. Every `grafana/dashboards/*.json` file, the `observability`/`node-exporter` namespaces, and every other namespace's Alloy-scrape/Mimir-egress NetworkPolicy rule went with them. See ADR-0041 for the full decision and its downstream impact on Argo Rollouts' canary AnalysisTemplate (also removed — canaries are now weight/pause-only, no automated SLO gate).
- **Object storage:** Garage was removed entirely 2026-09-07, no replacement (ADR-0002's
  Status) — the lab has no S3-compatible store any more; Terraform state moved to a
  plain local backend.
- **AWS emulation / ACK / KRO cloud-control-plane demo:** removed 2026-09-07, no
  replacement (ACK and moto: maintainer decision; KRO: orphaned dependent — its only
  ResourceGraphDefinition claimed an ACK Bucket, so it became dead weight the moment
  ACK/moto were gone) — see [ADR-0038](adr-0038-ack-kro-moto-cloud-control-plane.md)'s
  Status for the full removal note.
- **Secrets REMOVED 2026-09-07 (ADR-0042, supersedes ADR-0036 + ADR-0037):** Vault and
  External Secrets Operator were both removed as workloads with no replacement, per
  explicit maintainer direction — by the time they were cut, zero `ExternalSecret`
  resources remained anywhere in the repo (every component that had ever needed a
  Vault-held credential was already gone). No credential currently flowing through
  the lab needs an external secrets store; ArgoCD's admin password and every TLS
  certificate are natively generated in-cluster.
- **Git source REMOVED 2026-09-07 (self-hosted git, ADR-0033/ADR-0035):** first
  GitLab, then Forgejo, were removed entirely, no replacement — the repo lives only
  on its public GitHub remote now, and ArgoCD/Terraform read from it directly.
- **Harbor REMOVED 2026-09-07, no replacement** — see [ADR-0024](adr-0024-harbor-not-artifactory.md)'s
  Status for the full removal note.
- **Routing:** per-app UIs via Traefik with `*.127.0.0.1.nip.io` hostnames (no /etc/hosts). ArgoCD=`argocd.127.0.0.1.nip.io:8080`.
- **TiDB:** removed 2026-09-06 (maintainer decision, no replacement) — see ADR-0031/ADR-0032's Status for the full removal note.
- **Longhorn:** removed 2026-09-06 (maintainer decision, no replacement) — see ADR-0013's Status for the full removal note. `local-path` remains the only PVC provisioner in the lab.

## Operational rules
1. Plain-manifest pods need a `checksum/config` pod annotation bumped on ConfigMap changes to restart (Helm charts auto-roll).
2. Shell is **zsh** (unquoted `$var` does not word-split).

## From-scratch / DR
See [../DR.md](../DR.md) for the exact bootstrap order and `make up` automation.
