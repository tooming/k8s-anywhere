#!/usr/bin/env bash
# Shared filesystem paths for the NetworkPolicy bats tests (ADR-0016 §4 fan-out).
# Loaded via `load lib/networkpolicy-paths` from tests/networkpolicy.bats (the shared
# baseline) and every per-scope tests/networkpolicy-<scope>.bats. Centralising the
# paths here means a per-scope file never re-declares the shared set, and there is no
# shared monolith for parallel fan-out PRs to collide on.
REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
POLICIES="$REPO/gitops/network/policies"
DATA_NP="$REPO/gitops/data/networkpolicy"
CAPSTONE_NP="$REPO/gitops/apps/capstone/networkpolicy"
OBS_NP="$REPO/gitops/observability/networkpolicy"
VAULT_NP="$REPO/gitops/vault/networkpolicy"
STORAGE_NP="$REPO/gitops/storage/networkpolicy"
ARGOCD_NP="$REPO/gitops/argocd/networkpolicy"
MOTO_NP="$REPO/gitops/moto/networkpolicy"
ACK_NP="$REPO/gitops/ack/networkpolicy"
GATEWAY_NP="$REPO/gitops/network/networkpolicy"
TIDB_NP="$REPO/gitops/tidb/networkpolicy"
TIDB_ADMIN_NP="$REPO/gitops/tidb-admin/networkpolicy"
ENVOY_GW_NP="$REPO/gitops/envoy-gateway-system/networkpolicy"
ESO_NP="$REPO/gitops/external-secrets/networkpolicy"
KRO_NP="$REPO/gitops/kro/networkpolicy"
LAB_DEMO_NP="$REPO/gitops/apps/demo/networkpolicy"
INKLESS_NP="$REPO/gitops/inkless/networkpolicy"
ISTIO_SYSTEM_NP="$REPO/gitops/istio-system/networkpolicy"
LONGHORN_NP="$REPO/gitops/longhorn/networkpolicy"
ARTIFACTORY_NP="$REPO/gitops/artifactory/networkpolicy"
KYVERNO_NP="$REPO/gitops/kyverno/networkpolicy"
VELERO_NP="$REPO/gitops/velero/networkpolicy"
TRIVY_NP="$REPO/gitops/trivy-system/networkpolicy"
ARGO_ROLLOUTS_NP="$REPO/gitops/argo-rollouts/networkpolicy"
HARBOR_NP="$REPO/gitops/harbor/networkpolicy"
KARGO_NP="$REPO/gitops/kargo/networkpolicy"
NODE_EXPORTER_NP="$REPO/gitops/node-exporter/networkpolicy"
