#!/usr/bin/env bash
# Shared filesystem paths for the NetworkPolicy bats tests (ADR-0016 §4 fan-out).
# Loaded via `load lib/networkpolicy-paths` from tests/networkpolicy.bats (the shared
# baseline) and every per-scope tests/networkpolicy-<scope>.bats. Centralising the
# paths here means a per-scope file never re-declares the shared set, and there is no
# shared monolith for parallel fan-out PRs to collide on.
#
# Only vars for the project's current 4 always-on namespaces remain. Many more used to
# be declared here (data, capstone, observability, storage, tidb/tidb-admin,
# istio-system, longhorn, artifactory, kyverno, velero, argo-rollouts, harbor, kargo/
# kargo-project, keda, vault, external-secrets) — every one of those namespaces was
# removed entirely across several sessions (most on 2026-09-06/07, no replacement),
# and none of the vars had any remaining reference once its own
# networkpolicy-<scope>.bats file was deleted alongside it, so they were dropped here
# too rather than kept as dead declarations.
REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
POLICIES="$REPO/gitops/network/policies"
ARGOCD_NP="$REPO/gitops/argocd/networkpolicy"
GATEWAY_NP="$REPO/gitops/network/networkpolicy"
LAB_DEMO_NP="$REPO/gitops/apps/demo/networkpolicy"
CERT_MANAGER_NP="$REPO/gitops/cert-manager/networkpolicy"
