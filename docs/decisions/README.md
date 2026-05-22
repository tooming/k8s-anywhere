# Decisions

Version-controlled record of this lab's architecture decisions and working
agreements — kept in the repo (not just in an assistant's memory) so the
rationale travels with the code.

**When a decision is made or changed, update this folder.**

- [context.md](context.md) — current architecture, components, live decisions, and operational rules
- ADRs (one principle per file):
  - [ADR-0001](adr-0001-gitops-over-terraform-helm.md) — Terraform only bootstraps; workloads via ArgoCD
  - [ADR-0002](adr-0002-garage-not-minio.md) — Garage for S3-compatible storage (MinIO is out)
  - [ADR-0003](adr-0003-decoupled-no-spof.md) — Production-shaped, decoupled designs; no single-pod SPOFs
  - [ADR-0004](adr-0004-no-fabricated-content.md) — Dashboards/outputs show real, auto-discovered state
