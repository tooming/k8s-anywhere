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
  - [ADR-0005](adr-0005-spof-recreate-over-ha.md) — On one host, choose recoverability over (impossible) HA
  - [ADR-0006](adr-0006-grafana-native-git-sync.md) — Dashboards via Grafana native Git Sync (not the sidecar)
  - [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) — Off-cluster Garage as the Terraform-state backend
  - [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) — Envoy Gateway for north-south ingress (Gateway API, not Traefik)
  - [ADR-0009](adr-0009-rabbitmq-message-broker.md) — RabbitMQ as the lab's message broker (plain manifests, always-on)
  - [ADR-0010](adr-0010-redis-cache.md) — Redis as the lab's cache / key-value store (plain manifests, always-on)
