#!/usr/bin/env bats
# Clusterless structural tests for PSS-restricted fan-out to the data namespace
# (ADR-0017 §Staged rollout). Asserts the data namespace manifest and all four
# data workloads carry the required PSS restricted securityContext fields.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/data/rabbitmq/namespace.yaml"
  RABBITMQ="$REPO/gitops/data/rabbitmq/statefulset.yaml"
  VALKEY="$REPO/gitops/data/valkey/statefulset.yaml"
  RABBITMQ_LOAD="$REPO/gitops/data/demo/rabbitmq-load.yaml"
  VALKEY_LOAD="$REPO/gitops/data/demo/valkey-load.yaml"
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
}

# --- namespace PSA labels ----------------------------------------------------

@test "data namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "data namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "data namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "data namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "data namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

# --- RabbitMQ StatefulSet securityContext ------------------------------------
# Path-aware via yqs() so a regression back to a wrong/renamed key (the
# containerSecurityContext-vs-securityContext bug class this repo has hit
# repeatedly — KSM, node-exporter, Pyroscope, KRO) fails loudly instead of a
# bare grep silently passing because the value string exists anywhere in the
# file, possibly under the wrong key.

@test "rabbitmq StatefulSet sets runAsNonRoot: true" {
  [ "$(yqs '.spec.template.spec.securityContext.runAsNonRoot' "$RABBITMQ")" = "true" ]
}

@test "rabbitmq StatefulSet sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.template.spec.securityContext.seccompProfile.type' "$RABBITMQ")" = "RuntimeDefault" ]
}

@test "rabbitmq StatefulSet sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "$RABBITMQ")" = "false" ]
}

@test "rabbitmq StatefulSet sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$RABBITMQ")" = "true" ]
}

@test "rabbitmq StatefulSet drops ALL capabilities" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$RABBITMQ")" = "ALL" ]
}

# --- Valkey StatefulSet securityContext --------------------------------------

@test "valkey StatefulSet sets runAsNonRoot: true" {
  [ "$(yqs '.spec.template.spec.securityContext.runAsNonRoot' "$VALKEY")" = "true" ]
}

@test "valkey StatefulSet sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.template.spec.securityContext.seccompProfile.type' "$VALKEY")" = "RuntimeDefault" ]
}

@test "valkey StatefulSet sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "$VALKEY")" = "false" ]
}

@test "valkey StatefulSet sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$VALKEY")" = "true" ]
}

@test "valkey StatefulSet drops ALL capabilities" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$VALKEY")" = "ALL" ]
}

# --- rabbitmq-load Deployment securityContext --------------------------------

@test "rabbitmq-load Deployment sets runAsNonRoot: true" {
  [ "$(yqs '.spec.template.spec.securityContext.runAsNonRoot' "$RABBITMQ_LOAD")" = "true" ]
}

@test "rabbitmq-load Deployment sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.template.spec.securityContext.seccompProfile.type' "$RABBITMQ_LOAD")" = "RuntimeDefault" ]
}

@test "rabbitmq-load Deployment sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "$RABBITMQ_LOAD")" = "false" ]
}

@test "rabbitmq-load Deployment sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$RABBITMQ_LOAD")" = "true" ]
}

@test "rabbitmq-load Deployment drops ALL capabilities" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$RABBITMQ_LOAD")" = "ALL" ]
}

# --- valkey-load Deployment securityContext ----------------------------------

@test "valkey-load Deployment sets runAsNonRoot: true" {
  [ "$(yqs '.spec.template.spec.securityContext.runAsNonRoot' "$VALKEY_LOAD")" = "true" ]
}

@test "valkey-load Deployment sets seccompProfile.type: RuntimeDefault" {
  [ "$(yqs '.spec.template.spec.securityContext.seccompProfile.type' "$VALKEY_LOAD")" = "RuntimeDefault" ]
}

@test "valkey-load Deployment sets allowPrivilegeEscalation: false" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "$VALKEY_LOAD")" = "false" ]
}

@test "valkey-load Deployment sets readOnlyRootFilesystem: true" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$VALKEY_LOAD")" = "true" ]
}

@test "valkey-load Deployment drops ALL capabilities" {
  [ "$(yqs '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$VALKEY_LOAD")" = "ALL" ]
}
