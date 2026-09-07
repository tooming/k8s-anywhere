# Lab context & live decisions

A cloud-agnostic learning lab to see how a cloud-native platform fits together:
**Traefik · k3s · ArgoCD · Harbor · Vault · GitLab · Terraform/Terragrunt**
(plus Garage, External Secrets). This
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
| Cluster | k3d (Terraform/Terragrunt), Traefik bundled (ADR-0040) | k3s v1.36.4+k3s1 (pinned, ADR-0030), 2 nodes |
| GitOps engine | ArgoCD (Helm via Terraform = bootstrap) | reads from GitLab |
| Git source | GitLab CE omnibus (docker container) | host `:8929`, cluster `host.k3d.internal:8929` |
| Ingress | Traefik (bundled with k3s) | `IngressRoute` CRD; shared `TLSStore` in `lab-gateway` ns |
| Secrets | Vault (standalone+file PVC) + External Secrets Operator | k8s-auth, role `eso` |
| S3 object store | Garage (`storage` ns, PVC) | buckets: velero, plus per-app buckets |

## Live decisions
- **Ingress vs mesh:** Traefik = north-south (ADR-0040). The service-mesh learning objective (on-demand Istio ambient + Kiali, ADR-0012) was **removed 2026-09-06** (maintainer decision, no replacement) — see ADR-0012's Status for the full removal note.
- **Observability REMOVED 2026-09-06 (ADR-0041, supersedes ADR-0006 + ADR-0034):** the entire LGTM(P) stack (Alloy, Mimir, Loki, Tempo, Pyroscope), Grafana, kube-state-metrics, and node-exporter were removed as workloads with no replacement, per explicit maintainer direction. Every `grafana/dashboards/*.json` file, the `observability`/`node-exporter` namespaces, and every other namespace's Alloy-scrape/Mimir-egress NetworkPolicy rule went with them. See ADR-0041 for the full decision and its downstream impact on Argo Rollouts' canary AnalysisTemplate (also removed — canaries are now weight/pause-only, no automated SLO gate).
- **Object storage:** **Garage**, not MinIO (ADR-0002).
- **AWS emulation / ACK / KRO cloud-control-plane demo:** removed 2026-09-07, no
  replacement (ACK and moto: maintainer decision; KRO: orphaned dependent — its only
  ResourceGraphDefinition claimed an ACK Bucket, so it became dead weight the moment
  ACK/moto were gone) — see [ADR-0038](adr-0038-ack-kro-moto-cloud-control-plane.md)'s
  Status for the full removal note.
- **Secrets:** Vault + ESO. Pattern for any new secret: `vault kv put secret/...` then add an `ExternalSecret` in `gitops/secrets/` — never kubectl-create or commit raw secrets. Vault seals on restart → an interim **auto-unsealer** re-unseals from the `vault-keys` Secret (lab-only). Real KMS auto-unseal would need a cloud KMS / LocalStack Pro — not viable here.
- **Routing:** per-app UIs via Traefik with `*.127.0.0.1.nip.io` hostnames (no /etc/hosts). ArgoCD=`argocd.127.0.0.1.nip.io:8080`, Vault=`vault.127.0.0.1.nip.io:8080`, GitLab=`localhost:8929`.
- **TiDB:** removed 2026-09-06 (maintainer decision, no replacement) — see ADR-0031/ADR-0032's Status for the full removal note.
- **Longhorn:** removed 2026-09-06 (maintainer decision, no replacement) — see ADR-0013's Status for the full removal note. `local-path` remains the only PVC provisioner in the lab.

## Operational rules
1. **No dependency cycle:** never source ArgoCD's git credentials or Vault's unseal key *from Vault* (would cycle ArgoCD↔Vault). Verified acyclic: repo secret is Terraform-made; ESO manages only workload secrets.
2. Plain-manifest pods need a `checksum/config` pod annotation bumped on ConfigMap changes to restart (Helm charts auto-roll).
3. Shell is **zsh** (unquoted `$var` does not word-split).
4. `.gitignore` uses root-anchored `/secrets/` so `gitops/secrets/` (ExternalSecret manifests, not real secrets) commits.

## From-scratch / DR
See [../DR.md](../DR.md) for the exact bootstrap order and `make up` automation.
