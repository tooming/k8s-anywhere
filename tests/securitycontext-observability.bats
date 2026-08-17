#!/usr/bin/env bats
# Clusterless structural tests for PSS-restricted fan-out to the observability namespace
# (ADR-0017 §Staged rollout). Asserts the observability namespace manifest and all LGTMP
# workloads carry the required PSS restricted securityContext fields.
#
# node-exporter carve-out: hostPID and hostNetwork are explicitly set to false so the
# DaemonSet complies with the restricted namespace label. Alloy, Grafana, and Pyroscope
# all had their readOnlyRootFilesystem carve-out verified and tightened to true — see
# the alloy-storage emptyDir tests below for Alloy's added mount.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
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
# Pod-level fields live under `securityContext` (the chart's real key), NOT
# `podSecurityContext` (silent no-op in this chart's schema — found auditing
# PR #491). Path-aware via yqs() so a regression back to the wrong key fails
# these tests instead of silently passing a bare grep.

@test "kube-state-metrics Application sets securityContext.enabled: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.enabled' "$KSM")" = "true" ]
}

@test "kube-state-metrics Application sets securityContext.runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.runAsNonRoot' "$KSM")" = "true" ]
}

@test "kube-state-metrics Application sets securityContext.seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.seccompProfile.type' "$KSM")" = "RuntimeDefault" ]
}

@test "kube-state-metrics Application does NOT use the dead podSecurityContext key" {
  [ "$(yqs '.spec.source.helm.valuesObject.podSecurityContext // "absent"' "$KSM")" = "absent" ]
}

@test "kube-state-metrics Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$KSM"
  [ "$status" -eq 0 ]
}

@test "kube-state-metrics Application drops ALL capabilities" {
  run grep -q '\- ALL' "$KSM"
  [ "$status" -eq 0 ]
}

# Path-aware versions of the three checks above: the bare grep checks only
# confirm the field VALUES exist somewhere in the file, not that they're
# actually nested under the chart's real container-level key
# (`containerSecurityContext`, verified against this chart's own
# values.yaml/templates). Closes the gap the janitor sweep found in PR #493's
# otherwise-thorough fix for this same key-mismatch bug class (found while
# diffing KRO's chart values.yaml for auto/kro-bump-0-9 and re-auditing the
# other charts already fixed for it).

@test "kube-state-metrics Application nests allowPrivilegeEscalation under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.allowPrivilegeEscalation' "$KSM")" = "false" ]
}

@test "kube-state-metrics Application nests readOnlyRootFilesystem under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.readOnlyRootFilesystem' "$KSM")" = "true" ]
}

@test "kube-state-metrics Application nests dropped ALL capabilities under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.capabilities.drop[0]' "$KSM")" = "ALL" ]
}

# --- kube-state-metrics chart-pin recurrence guard ----------------------------
# Packaging-only currency bump (appVersion unchanged) — see docs/done/ entry.

@test "kube-state-metrics Application pins chart version 8.3.1" {
  run grep -q 'targetRevision: 8.3.1' "$KSM"
  [ "$status" -eq 0 ]
}

@test "kube-state-metrics Application does not pin the stale 8.3.0 version" {
  run grep -q 'targetRevision: 8.3.0' "$KSM"
  [ "$status" -ne 0 ]
}

@test "kube-state-metrics Application does not pin the stale 8.0.0 version" {
  run grep -q 'targetRevision: 8.0.0' "$KSM"
  [ "$status" -ne 0 ]
}

@test "kube-state-metrics Application does not pin the stale 8.1.3 version" {
  run grep -q 'targetRevision: 8.1.3' "$KSM"
  [ "$status" -ne 0 ]
}

@test "kube-state-metrics Application does not pin the stale 8.2.0 version" {
  run grep -q 'targetRevision: 8.2.0' "$KSM"
  [ "$status" -ne 0 ]
}

# --- Alloy Application securityContext ---------------------------------------
# Pod-level fields live under `global.podSecurityContext` (the chart's real
# key), NOT `controller.podSecurityContext` (silent no-op in this chart's
# schema). Path-aware via yqs() so a regression back to the wrong key fails
# these tests instead of silently passing a bare grep.

@test "alloy Application sets global.podSecurityContext.runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.global.podSecurityContext.runAsNonRoot' "$ALLOY")" = "true" ]
}

@test "alloy Application sets global.podSecurityContext.seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.global.podSecurityContext.seccompProfile.type' "$ALLOY")" = "RuntimeDefault" ]
}

@test "alloy Application does NOT use the dead controller.podSecurityContext key" {
  [ "$(yqs '.spec.source.helm.valuesObject.controller.podSecurityContext // "absent"' "$ALLOY")" = "absent" ]
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
# Pod-level fields live under `securityContext` (the chart's real key), NOT
# `podSecurityContext` (silent no-op in this chart's schema). Path-aware via
# yqs() -- a bare grep for these field values would also match the unrelated
# extraInitContainers (ca-bundle) block below, which sets its own inline
# securityContext and would mask a regression here.

@test "grafana Application sets securityContext.runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.runAsNonRoot' "$GRAFANA")" = "true" ]
}

@test "grafana Application sets securityContext.fsGroup: 472" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.fsGroup' "$GRAFANA")" = "472" ]
}

@test "grafana Application sets securityContext.seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.seccompProfile.type' "$GRAFANA")" = "RuntimeDefault" ]
}

@test "grafana Application does NOT use the dead podSecurityContext key" {
  [ "$(yqs '.spec.source.helm.valuesObject.podSecurityContext // "absent"' "$GRAFANA")" = "absent" ]
}

@test "grafana Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "grafana Application drops ALL capabilities" {
  run grep -q '\- ALL' "$GRAFANA"
  [ "$status" -eq 0 ]
}

@test "grafana Application sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$GRAFANA"
  [ "$status" -eq 0 ]
}

# Path-aware versions: see the kube-state-metrics block above for why these
# close a gap the bare grep checks leave open (same recurrence-guard sweep).

@test "grafana Application nests allowPrivilegeEscalation under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.allowPrivilegeEscalation' "$GRAFANA")" = "false" ]
}

@test "grafana Application nests readOnlyRootFilesystem under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.readOnlyRootFilesystem' "$GRAFANA")" = "true" ]
}

@test "grafana Application nests dropped ALL capabilities under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.capabilities.drop[0]' "$GRAFANA")" = "ALL" ]
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

# --- Pyroscope container-level securityContext -------------------------------
# Container-level fields live under `pyroscope.securityContext` (the chart's
# real key, verified against templates/deployments-statefulsets.yaml), NOT
# `containerSecurityContext` (silent no-op in this chart's schema — the same
# key-mismatch bug class PR #493 fixed for ksm/node-exporter/grafana/alloy).
# Path-aware via yqs() so a regression back to the dead key fails these tests
# instead of silently passing a bare grep.

@test "pyroscope Application sets securityContext.allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.source.helm.valuesObject.pyroscope.securityContext.allowPrivilegeEscalation' "$PYROSCOPE")" = "false" ]
}

@test "pyroscope Application drops ALL capabilities via securityContext.capabilities" {
  [ "$(yqs '.spec.source.helm.valuesObject.pyroscope.securityContext.capabilities.drop[0]' "$PYROSCOPE")" = "ALL" ]
}

@test "pyroscope Application sets securityContext.readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.pyroscope.securityContext.readOnlyRootFilesystem' "$PYROSCOPE")" = "true" ]
}

@test "pyroscope Application does NOT use the dead containerSecurityContext key" {
  [ "$(yqs '.spec.source.helm.valuesObject.pyroscope.containerSecurityContext // "absent"' "$PYROSCOPE")" = "absent" ]
}

# --- node-exporter Application securityContext + carve-out -------------------
# Pod-level fields live under `securityContext` (the chart's real key), NOT
# `podSecurityContext` (silent no-op in this chart's schema). Path-aware via
# yqs() so a regression back to the wrong key fails these tests.

@test "node-exporter Application sets securityContext.runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.runAsNonRoot' "$NODE_EXPORTER")" = "true" ]
}

@test "node-exporter Application sets securityContext.seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.seccompProfile.type' "$NODE_EXPORTER")" = "RuntimeDefault" ]
}

@test "node-exporter Application does NOT use the dead podSecurityContext key" {
  [ "$(yqs '.spec.source.helm.valuesObject.podSecurityContext // "absent"' "$NODE_EXPORTER")" = "absent" ]
}

@test "node-exporter Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter Application drops ALL capabilities" {
  run grep -q '\- ALL' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

# Path-aware versions: see the kube-state-metrics block above for why these
# close a gap the bare grep checks leave open (same recurrence-guard sweep).

@test "node-exporter Application nests allowPrivilegeEscalation under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.allowPrivilegeEscalation' "$NODE_EXPORTER")" = "false" ]
}

@test "node-exporter Application nests readOnlyRootFilesystem under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.readOnlyRootFilesystem' "$NODE_EXPORTER")" = "true" ]
}

@test "node-exporter Application nests dropped ALL capabilities under containerSecurityContext (not just present anywhere)" {
  [ "$(yqs '.spec.source.helm.valuesObject.containerSecurityContext.capabilities.drop[0]' "$NODE_EXPORTER")" = "ALL" ]
}

@test "node-exporter has hostPID disabled (PSS restricted compliance)" {
  run grep -q 'hostPID: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}

@test "node-exporter has hostNetwork disabled (PSS restricted compliance)" {
  run grep -q 'hostNetwork: false' "$NODE_EXPORTER"
  [ "$status" -eq 0 ]
}
