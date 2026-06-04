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
  - [ADR-0011](adr-0011-artifactory-not-nexus.md) — Artifactory as the on-demand artifact registry (not Nexus)
  - [ADR-0012](adr-0012-istio-ambient-not-sidecar.md) — Istio ambient mesh + Kiali on-demand (not sidecar)
  - [ADR-0013](adr-0013-longhorn-block-storage.md) — Longhorn distributed block storage on-demand
  - [ADR-0014](adr-0014-cilium-not-flannel-policy.md) — Cilium CNI, not k3s's bundled Flannel + NetworkPolicy controller
  - [ADR-0015](adr-0015-inkless-diskless-kafka.md) — Aiven Inkless (diskless Kafka) on-demand, backed by Garage S3
  - [ADR-0016](adr-0016-default-deny-networkpolicy.md) — Default-deny NetworkPolicy per namespace (Cilium-enforced)
  - [ADR-0017](adr-0017-pod-security-standards-restricted.md) — Pod Security Standards `restricted` profile across all namespaces
