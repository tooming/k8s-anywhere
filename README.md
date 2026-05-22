# k8s-lab

A localhost learning lab that wires a full cloud-native platform together on a single Mac, so you can see how the pieces fit:

**Envoy · k3s · ArgoCD · TiDB · Vault · GitLab · Terraform/Terragrunt · Mimir · Loki**

The shape is a **GitOps platform**: Terraform/Terragrunt bootstraps a local Kubernetes cluster, GitLab holds the manifests, and ArgoCD continuously syncs everything else into the cluster.

See [docs/00-architecture.md](docs/00-architecture.md) for the full picture and the learning path.

## Constraints

This lab targets a **16 GB Mac**, so it is **modular**: a light always-on *core*, plus heavy areas you bring up one at a time. You cannot run GitLab + TiDB + full observability simultaneously — the `Makefile` profiles keep you within budget.

| Profile         | Components                            | ~RAM    |
|-----------------|---------------------------------------|---------|
| core (always)   | k3s + Envoy Gateway + ArgoCD + Vault  | 3–4 GB  |
| `gitlab`        | GitLab CE (omnibus container)         | 4–6 GB  |
| `tidb`          | tidb-operator + PD / TiKV / TiDB      | 3–4 GB  |
| `obs`           | Mimir + Loki + Grafana + Alloy        | 3–4 GB  |

## Quickstart

```sh
make preflight      # check required tools are installed
make colima-up      # start the container runtime VM (12 GB)
make cluster-up     # create the k3d cluster (Terraform / Terragrunt)
make bootstrap      # install ArgoCD + connect GitLab as the GitOps source
```

Then bring up one heavy profile at a time, e.g. `make obs-up` / `make obs-down`.
Run `make` with no target for the full list. `make status` shows RAM + running pods.

## Layout

- `infra/`  — Terraform modules + Terragrunt live config (the bootstrap layer)
- `gitops/` — what ArgoCD watches: app-of-apps → `platform/` `data/` `observability/` `apps/`
- `gitlab/` — GitLab omnibus docker-compose
- `scripts/`, `docs/`
