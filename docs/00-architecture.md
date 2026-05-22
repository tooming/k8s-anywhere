# Architecture & Learning Path

## The big idea

Every tool in this lab has a job in a single coherent system: a **GitOps-driven Kubernetes platform**. Rather than learning nine tools in isolation, you build one platform where each tool occupies a clear role.

```
   ┌─────────────────────┐
   │ Terraform/Terragrunt │   bootstraps + configures (imperative, run by you)
   └──────────┬───────────┘
              │ creates cluster, installs ArgoCD, configures GitLab
              ▼
   ┌─────────────────────┐        ┌──────────────────┐
   │   k3s  (via k3d)     │◄───────│      GitLab      │  git = source of truth
   │   Kubernetes cluster │        │  (CE omnibus)    │
   └──────────┬───────────┘        └────────┬─────────┘
              │                              │ ArgoCD watches the gitops repo
              │        ┌─────────────────────┘
              ▼        ▼
        ┌───────────────────┐
        │      ArgoCD       │  GitOps engine — reconciles cluster → git
        └─────────┬─────────┘
                  │ deploys (app-of-apps)
   ┌──────────────┼───────────────┬───────────────┬──────────────┐
   ▼              ▼               ▼               ▼              ▼
┌────────┐   ┌────────┐    ┌───────────┐   ┌──────────┐   ┌──────────┐
│ Envoy  │   │ Vault  │    │   TiDB    │   │  Mimir   │   │   Loki   │
│Gateway │   │secrets │    │ database  │   │ metrics  │   │   logs   │
└───┬────┘   └────────┘    └───────────┘   └────┬─────┘   └────┬─────┘
    │ north-south traffic                       │              │
    ▼                                           └──► Grafana ◄──┘
 demo apps ──(emit metrics + logs, read secrets from Vault)
```

## Who does what

| Tool | Role in the platform |
|------|----------------------|
| **k3s** (via **k3d**) | The Kubernetes cluster — the substrate everything runs on. k3d runs k3s inside Docker containers, which is how we get k8s on a Mac. |
| **Terraform / Terragrunt** | Imperative bootstrap: create the cluster, install ArgoCD, configure GitLab (projects, tokens). Terragrunt keeps the Terraform DRY across "live" config. This is the *only* layer you run by hand. |
| **GitLab** | The git **source of truth**. Holds the `gitops/` manifests. Later: GitLab CI to build/test images. |
| **ArgoCD** | The **GitOps engine**. Watches the GitLab repo and makes the cluster match it. Everything below is deployed *through* ArgoCD, not by hand. |
| **Envoy** (Gateway) | North-south **ingress / API gateway**. External traffic enters the cluster here and is routed to apps via the Kubernetes Gateway API. |
| **Vault** | **Secrets management**. Apps get DB passwords, tokens, etc. from Vault instead of hardcoded k8s Secrets. |
| **TiDB** | A distributed, MySQL-compatible **database** (PD + TiKV + TiDB tiers), deployed by its operator. A demo app talks to it. |
| **Mimir** | Scalable, Prometheus-compatible **metrics** storage. Long-term home for cluster + app + Envoy metrics. |
| **Loki** | **Log** aggregation — like Prometheus, but for logs. |
| **Grafana** | The single pane of glass over Mimir (metrics) and Loki (logs). |

## The GitOps flow (the part worth internalizing)

1. You change a manifest in `gitops/` and push to **GitLab**.
2. **ArgoCD** notices the git commit and compares it to the live cluster.
3. ArgoCD applies the diff — the cluster converges to match git.
4. You never `kubectl apply` workloads by hand; git is the only way in.

Terraform/Terragrunt is the exception: it builds the *foundation* that GitOps then runs on. Rule of thumb — **Terraform builds the platform, ArgoCD runs on the platform.**

## Why modular (the 16 GB reality)

A 16 GB Mac cannot hold the whole stack at once. So the lab is split into profiles (see the README table). A light **core** (k3s + Envoy + ArgoCD + Vault) stays up; you bring up **one** heavy area at a time (`gitlab`, `tidb`, or `obs`) via the `Makefile`. GitLab runs as a standalone container (not in-cluster) so its 4–6 GB footprint stays off the cluster and can be stopped independently.

## Suggested learning path

0. **Toolchain + Colima** — container runtime VM. ✅ done first
1. **Foundation** — `cluster-up` (k3d via Terraform) → `bootstrap` (ArgoCD + GitLab wiring). *You are here.*
2. **Core platform** — Envoy Gateway, then Vault, deployed via ArgoCD.
3. **Observability** — Mimir + Loki + Grafana, so everything afterward is visible.
4. **Data** — TiDB + a demo app that reads its credentials from Vault.
5. **Tie it together** — GitLab CI builds an image → ArgoCD deploys it → Envoy routes it → Grafana shows its metrics & logs → Vault holds its secrets.
