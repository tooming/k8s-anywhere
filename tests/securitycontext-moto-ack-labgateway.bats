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
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
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
# Path-aware via yqs() so a regression back to a wrong/renamed key (the
# containerSecurityContext-vs-securityContext bug class this repo has hit
# repeatedly — KSM, node-exporter, Pyroscope, KRO) fails loudly instead of a
# bare grep silently passing because the value string exists anywhere in the
# file, possibly under the wrong key.

@test "moto Deployment sets runAsNonRoot: true" {
  [ "$(yqs '.spec.template.spec.securityContext.runAsNonRoot' "$MOTO_DEPLOY")" = "true" ]
}

@test "moto Deployment sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.template.spec.securityContext.seccompProfile.type' "$MOTO_DEPLOY")" = "RuntimeDefault" ]
}

@test "moto Deployment sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "$MOTO_DEPLOY")" = "false" ]
}

@test "moto Deployment sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$MOTO_DEPLOY")" = "true" ]
}

@test "moto Deployment drops ALL capabilities" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$MOTO_DEPLOY")" = "ALL" ]
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
# Path-aware via yqs(); see the moto block above for why.

@test "ack-s3 Application sets runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.podSecurityContext.runAsNonRoot' "$ACK_S3")" = "true" ]
}

@test "ack-s3 Application sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.podSecurityContext.seccompProfile.type' "$ACK_S3")" = "RuntimeDefault" ]
}

@test "ack-s3 Application sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.allowPrivilegeEscalation' "$ACK_S3")" = "false" ]
}

@test "ack-s3 Application sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.readOnlyRootFilesystem' "$ACK_S3")" = "true" ]
}

@test "ack-s3 Application drops ALL capabilities" {
  [ "$(yqs '.spec.source.helm.valuesObject.securityContext.capabilities.drop[0]' "$ACK_S3")" = "ALL" ]
}

# --- kro Application securityContext (Helm valuesObject) ---------------------
# Path-aware via yqs(); see the moto block above for why. Nested one level
# deeper (under .deployment.) than ack-s3 — this chart's own values schema
# (verified against gitops/platform/kro.yaml directly).

@test "kro Application sets runAsNonRoot: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.deployment.podSecurityContext.runAsNonRoot' "$KRO")" = "true" ]
}

@test "kro Application sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.source.helm.valuesObject.deployment.podSecurityContext.seccompProfile.type' "$KRO")" = "RuntimeDefault" ]
}

@test "kro Application sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.source.helm.valuesObject.deployment.securityContext.allowPrivilegeEscalation' "$KRO")" = "false" ]
}

@test "kro Application sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.source.helm.valuesObject.deployment.securityContext.readOnlyRootFilesystem' "$KRO")" = "true" ]
}

@test "kro Application drops ALL capabilities" {
  [ "$(yqs '.spec.source.helm.valuesObject.deployment.securityContext.capabilities.drop[0]' "$KRO")" = "ALL" ]
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
