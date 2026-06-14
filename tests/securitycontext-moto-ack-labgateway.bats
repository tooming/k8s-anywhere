#!/usr/bin/env bats
# Clusterless structural tests for PSS-restricted fan-out to the moto, ack-system,
# and lab-gateway namespaces (ADR-0017 §Staged rollout, CHARTER Objective O2).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  MOTO_NS="$REPO/gitops/moto/namespace.yaml"
  MOTO_DEPLOY="$REPO/gitops/moto/deployment.yaml"
  ACK_NS="$REPO/gitops/ack/namespace.yaml"
  ACK_S3="$REPO/gitops/platform/ack-s3.yaml"
  KRO="$REPO/gitops/platform/kro.yaml"
  GW_NS="$REPO/gitops/network/namespace.yaml"
}

# --- moto namespace PSA labels -----------------------------------------------

@test "moto namespace.yaml exists" {
  [ -f "$MOTO_NS" ]
}

@test "moto namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$MOTO_NS"
  [ "$status" -eq 0 ]
}

@test "moto namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$MOTO_NS"
  [ "$status" -eq 0 ]
}

@test "moto namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$MOTO_NS"
  [ "$status" -eq 0 ]
}

@test "moto namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$MOTO_NS"
  [ "$status" -eq 0 ]
}

# --- moto Deployment securityContext -----------------------------------------

@test "moto Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

@test "moto Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

@test "moto Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

@test "moto Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

@test "moto Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

@test "moto Deployment mounts tmp emptyDir for writable paths" {
  run grep -q 'emptyDir' "$MOTO_DEPLOY"
  [ "$status" -eq 0 ]
}

# --- ack-system namespace PSA labels -----------------------------------------

@test "ack-system namespace.yaml exists" {
  [ -f "$ACK_NS" ]
}

@test "ack-system namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$ACK_NS"
  [ "$status" -eq 0 ]
}

@test "ack-system namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$ACK_NS"
  [ "$status" -eq 0 ]
}

@test "ack-system namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$ACK_NS"
  [ "$status" -eq 0 ]
}

@test "ack-system namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$ACK_NS"
  [ "$status" -eq 0 ]
}

# --- ack-s3 Application securityContext (Helm valuesObject) ------------------

@test "ack-s3 Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$ACK_S3"
  [ "$status" -eq 0 ]
}

@test "ack-s3 Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$ACK_S3"
  [ "$status" -eq 0 ]
}

@test "ack-s3 Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$ACK_S3"
  [ "$status" -eq 0 ]
}

@test "ack-s3 Application sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$ACK_S3"
  [ "$status" -eq 0 ]
}

@test "ack-s3 Application drops ALL capabilities" {
  run grep -q '\- ALL' "$ACK_S3"
  [ "$status" -eq 0 ]
}

# --- kro Application securityContext (Helm valuesObject) ---------------------

@test "kro Application sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$KRO"
  [ "$status" -eq 0 ]
}

@test "kro Application sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$KRO"
  [ "$status" -eq 0 ]
}

@test "kro Application sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$KRO"
  [ "$status" -eq 0 ]
}

@test "kro Application sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$KRO"
  [ "$status" -eq 0 ]
}

@test "kro Application drops ALL capabilities" {
  run grep -q '\- ALL' "$KRO"
  [ "$status" -eq 0 ]
}

# --- lab-gateway namespace PSA labels ----------------------------------------

@test "lab-gateway namespace.yaml exists" {
  [ -f "$GW_NS" ]
}

@test "lab-gateway namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}

@test "lab-gateway namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$GW_NS"
  [ "$status" -eq 0 ]
}
