# ADR-0001 — Terraform only bootstraps; workloads via ArgoCD

**Decision.** Terraform/Terragrunt does the day-0 seam ONLY: create the cluster,
install the GitOps controller (ArgoCD), configure GitLab. Every in-cluster
workload (Envoy, Vault, TiDB, Mimir, Loki, Grafana, Garage, …) is an **ArgoCD
Application** synced from GitLab. ArgoCD renders Helm charts itself, so Helm is
still used — just driven by continuous reconciliation, not `terraform apply`.

**Why.** "Helm via Terraform" is point-in-time with a second source of truth and
state drift. GitOps gives reconciliation, drift detection, and self-heal. You
need exactly one imperative step to install the engine — that's the only
acceptable use of TF-Helm here.

**Corollaries.**
- The **git source (GitLab) is bootstrap layer too** — ArgoCD reads *from* it, so
  it can't be created *by* ArgoCD (chicken-and-egg). It runs as a standalone
  omnibus container (also keeps its 3–4 GB off the cluster).
- **Never** put ArgoCD's git credentials or Vault's unseal key in Vault → that
  would create an ArgoCD↔Vault cycle.

**Status.** Adopted. ArgoCD + the GitLab repo-secret are Terraform/bootstrap;
everything else is in `gitops/`.
