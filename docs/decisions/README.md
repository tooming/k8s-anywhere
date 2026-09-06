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
  - [ADR-0006](adr-0006-grafana-native-git-sync.md) — Dashboards via Grafana native Git Sync (not the sidecar) — **Superseded by ADR-0041**
  - [ADR-0007](adr-0007-off-cluster-garage-tfstate-backend.md) — Off-cluster Garage as the Terraform-state backend
  - [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) — Envoy Gateway for north-south ingress (Gateway API, not Traefik) — **Superseded by ADR-0040**
  - [ADR-0009](adr-0009-rabbitmq-message-broker.md) — RabbitMQ as the lab's message broker (plain manifests, always-on)
  - [ADR-0010](adr-0010-redis-cache.md) — Redis as the lab's cache / key-value store — **Superseded by ADR-0018**
  - [ADR-0011](adr-0011-artifactory-not-nexus.md) — Artifactory as the on-demand artifact registry (not Nexus) — **Superseded by ADR-0024**
  - [ADR-0012](adr-0012-istio-ambient-not-sidecar.md) — Istio ambient mesh + Kiali on-demand (not sidecar) — **Removed 2026-09-06, no replacement**
  - [ADR-0013](adr-0013-longhorn-block-storage.md) — Longhorn distributed block storage on-demand — **Removed 2026-09-06, no replacement**
  - [ADR-0014](adr-0014-cilium-not-flannel-policy.md) — Cilium CNI, not k3s's bundled Flannel + NetworkPolicy controller
  - [ADR-0015](adr-0015-inkless-diskless-kafka.md) — Aiven Inkless (diskless Kafka) on-demand, backed by Garage S3 — **Removed 2026-09-05, no replacement**
  - [ADR-0016](adr-0016-default-deny-networkpolicy.md) — Default-deny NetworkPolicy per namespace (Cilium-enforced)
  - [ADR-0017](adr-0017-pod-security-standards-restricted.md) — Pod Security Standards `restricted` profile across all namespaces
  - [ADR-0018](adr-0018-valkey-not-redis.md) — Valkey as the lab's cache / key-value store (supersedes ADR-0010)
  - [ADR-0019](adr-0019-kyverno-admission-engine.md) — Kyverno as the lab's admission policy engine (not OPA Gatekeeper)
  - [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) — Argo Rollouts for progressive delivery (weight/pause canaries via Traefik's native traffic-routing, ADR-0040; SLO gate removed alongside Mimir, ADR-0041)
  - [ADR-0021](adr-0021-velero-backup-restore.md) — Velero for cluster + PVC backup/restore to Garage S3
  - [ADR-0022](adr-0022-trivy-operator-supply-chain.md) — Trivy Operator for continuous vulnerability + SBOM scanning
  - [ADR-0023](adr-0023-kargo-promotion-pipeline.md) — Kargo for GitOps promotion pipelines (multi-stage, Warehouse-gated)
  - [ADR-0024](adr-0024-harbor-not-artifactory.md) — Harbor as the on-demand artifact registry (supersedes ADR-0011)
  - [ADR-0025](adr-0025-free-oss-tiers-only.md) — Every dependency runs on a free/OSS tier (verify the needed feature is in it, not just the edition)
  - [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) — Cloud-agnostic infrastructure target: pluggable Terraform backends, localhost stays the free default
  - [ADR-0027](adr-0027-first-cloud-backend-oracle-always-free-k3s.md) — First cloud backend: Oracle Cloud Always Free (Ampere A1) + self-managed k3s
  - [ADR-0028](adr-0028-cert-manager-tls-lifecycle.md) — cert-manager for automated TLS certificate lifecycle (self-signed root CA, not public ACME)
  - [ADR-0029](adr-0029-keda-event-driven-autoscaling.md) — KEDA for event-driven autoscaling (RabbitMQ/Prometheus-triggered scaling, augments the stock HPA)
  - [ADR-0030](adr-0030-pin-k3s-version-explicitly.md) — Pin k3s to an explicit version on every backend
  - [ADR-0031](adr-0031-tidb-operator-version-policy.md) — TiDB Operator version-pin policy: hold at the 1.6.x line — **Removed 2026-09-06, no replacement**
  - [ADR-0032](adr-0032-tidb-version-policy.md) — TiDB database version-pin policy: hold at the v8.5.x line — **Removed 2026-09-06, no replacement**
  - [ADR-0033](adr-0033-gitlab-git-source-and-ci.md) — GitLab (self-hosted) as the lab's git source of truth + CI runner — **Superseded by ADR-0035**
  - [ADR-0034](adr-0034-lgtmp-observability-stack.md) — Grafana LGTM(P) stack internals + kube-state-metrics/node-exporter for observability — **Superseded by ADR-0041**
  - [ADR-0035](adr-0035-forgejo-not-gitlab.md) — Forgejo (self-hosted) as the lab's git source of truth + CI runner (supersedes ADR-0033)
  - [ADR-0036](adr-0036-external-secrets-vault-sync.md) — External Secrets Operator for Vault-backed secret sync (retroactive governance record)
  - [ADR-0037](adr-0037-vault-secrets-management.md) — HashiCorp Vault for secrets management (retroactive governance record)
  - [ADR-0038](adr-0038-ack-kro-moto-cloud-control-plane.md) — moto + ACK (S3) + KRO for the cloud-control-plane demo pattern (retroactive governance record)
  - [ADR-0039](adr-0039-s3manager-garage-browser-ui.md) — s3manager as the lab's Garage (S3) browser UI (retroactive governance record)
  - [ADR-0040](adr-0040-traefik-not-envoy-gateway.md) — Traefik for north-south ingress (supersedes ADR-0008)
  - [ADR-0041](adr-0041-remove-observability-stack.md) — Remove the observability stack entirely (supersedes ADR-0006, ADR-0034)
