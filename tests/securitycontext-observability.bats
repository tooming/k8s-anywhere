#!/usr/bin/env bats
# Clusterless structural tests for PSS-restricted fan-out to the observability namespace
# (ADR-0017 §Staged rollout). Asserts the observability namespace manifest and all LGTMP
# workloads carry the required PSS restricted securityContext fields.
#
# node-exporter carve-out: hostPID and hostNetwork are explicitly set to false so the
# DaemonSet complies with the restricted namespace label. readOnlyRootFilesystem carve-outs
# for Grafana and Pyroscope are noted in the PR and tracked as follow-up items (Alloy's
# was tightened to true — see the alloy-storage emptyDir tests below).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/observability/mimir/namespace.yaml"
  MIMIR="$REPO/gitops/observability/mimir/deployment.yaml"
  LOKI="$REPO/gitops/observability/loki/deployment.yaml"
  TEMPO="$REPO/gitops/observability/tempo/deployment.yaml"
  KSM="$REPO/gitops/platform/observability-ksm.yaml"
  ALLOY="$REPO/gitops/platform/observability-alloy.yaml"
  GRAFANA="$REPO/gitops/platform/observability-grafana.yaml"
  PYROSCOPE="$REPO/gitops/platform/observability-pyroscope.yaml"
  NODE_EXPORTER="$REPO/gitops/platform/observability-node-exporter.yaml"
}

# --- namespace PSA labels (ADR-0017 §Layer 2) ---------------------------------

@test "observability namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "observability namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "observability namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "observability namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "observability namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

# --- Mimir Deployment securityContext ----------------------------------------

@test "mimir Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$MIMIR"
  [ "$status" -eq 0 ]
}

@test "mimir Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$MIMIR"
  [ "$status" -eq 0 ]
}

@test "mimir Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$MIMIR"
  [ "$status" -eq 0 ]
}

@test "mimir Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$MIMIR"
  [ "$status" -eq 0 ]
}

@test "mimir Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$MIMIR"
  [ "$status" -eq 0 ]
}

# --- Loki Deployment securityContext -----------------------------------------

@test "loki Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$LOKI"
  [ "$status" -eq 0 ]
}

@test "loki Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$LOKI"
  [ "$status" -eq 0 ]
}

@test "loki Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$LOKI"
  [ "$status" -eq 0 ]
}

@test "loki Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$LOKI"
  [ "$status" -eq 0 ]
}

@test "loki Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$LOKI"
  [ "$status" -eq 0 ]
}

# --- Tempo Deployment securityContext ----------------------------------------

@test "tempo Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$TEMPO"
  [ "$status" -eq 0 ]
}

@test "tempo Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$TEMPO"
  [ "$status" -eq 0 ]
}

@test "tempo Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$TEMPO"
  [ "$status" -eq 0 ]
}

@test "tempo Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$TEMPO"
  [ "$status" -eq 0 ]
}

@test "tempo Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$TEMPO"
  [ "$status" -eq 0 ]
}

# --- kube-state-metrics Application securityContext --------------------------

@test "kube-state-metrics Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$KSM"
  [ "$status" -eq 0 ]
}

@test "kube-state-metrics Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$KSM"
  [ "$status" -eq 0 ]
}

@test "kube-state-metrics Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$KSM"
  [ "$status" -eq 0 ]
}

@test "kube-state-metrics Application drops ALL capabilities" {
  run grep -q '\- ALL' "$KSM"
  [ "$status" -eq 0 ]
}

# --- Alloy Application securityContext ---------------------------------------

@test "alloy Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "alloy Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "alloy Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "alloy Application drops ALL capabilities" {
  run grep -q '\- ALL' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "alloy Application sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$ALLOY"
  [ "$status" -eq 0 ]
}

@test "alloy Application backs /tmp/alloy (storage.path) with an emptyDir, not root fs" {
  run grep -q 'mountPath: /tmp/alloy' "$ALLOY"
  [ "$status" -eq 0 ]
  run grep -q 'name: alloy-storage' "$ALLOY"
  [ "$status" -eq 0 ]
}

# --- Grafana Application securityContext -------------------------------------

@test "grafana Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "grafana Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "grafana Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "grafana Application drops ALL capabilities" {
  run grep -q '\- ALL' "$GRAFANA"
  [ "$status" -eq 0 ]
}

# --- Pyroscope Application securityContext -----------------------------------

@test "pyroscope Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$PYROSCOPE"
  [ "$status" -eq 0 ]
}

@test "pyroscope Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$PYROSCOPE"
  [ "$status" -eq 0 ]
}

@test "pyroscope Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$PYROSCOPE"
  [ "$status" -eq 0 ]
}

@test "pyroscope Application drops ALL capabilities" {
  run grep -q '\- ALL' "$PYROSCOPE"
  [ "$status" -eq 0 ]
}

# --- node-exporter Application securityContext + carve-out -------------------

@test "node-exporter Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter Application drops ALL capabilities" {
  run grep -q '\- ALL' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter has hostPID disabled (PSS restricted compliance)" {
  run grep -q 'hostPID: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter has hostNetwork disabled (PSS restricted compliance)" {
  run grep -q 'hostNetwork: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}
