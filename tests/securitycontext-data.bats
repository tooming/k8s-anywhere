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

@test "rabbitmq StatefulSet sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$RABBITMQ"
  [ "$status" -eq 0 ]
}

@test "rabbitmq StatefulSet sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$RABBITMQ"
  [ "$status" -eq 0 ]
}

@test "rabbitmq StatefulSet sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$RABBITMQ"
  [ "$status" -eq 0 ]
}

@test "rabbitmq StatefulSet sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$RABBITMQ"
  [ "$status" -eq 0 ]
}

@test "rabbitmq StatefulSet drops ALL capabilities" {
  run grep -q '\- ALL' "$RABBITMQ"
  [ "$status" -eq 0 ]
}

# --- Valkey StatefulSet securityContext --------------------------------------

@test "valkey StatefulSet sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$VALKEY"
  [ "$status" -eq 0 ]
}

@test "valkey StatefulSet sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$VALKEY"
  [ "$status" -eq 0 ]
}

@test "valkey StatefulSet sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$VALKEY"
  [ "$status" -eq 0 ]
}

@test "valkey StatefulSet sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$VALKEY"
  [ "$status" -eq 0 ]
}

@test "valkey StatefulSet drops ALL capabilities" {
  run grep -q '\- ALL' "$VALKEY"
  [ "$status" -eq 0 ]
}

# --- rabbitmq-load Deployment securityContext --------------------------------

@test "rabbitmq-load Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$RABBITMQ_LOAD"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$RABBITMQ_LOAD"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$RABBITMQ_LOAD"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$RABBITMQ_LOAD"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$RABBITMQ_LOAD"
  [ "$status" -eq 0 ]
}

# --- valkey-load Deployment securityContext ----------------------------------

@test "valkey-load Deployment sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$VALKEY_LOAD"
  [ "$status" -eq 0 ]
}

@test "valkey-load Deployment sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$VALKEY_LOAD"
  [ "$status" -eq 0 ]
}

@test "valkey-load Deployment sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$VALKEY_LOAD"
  [ "$status" -eq 0 ]
}

@test "valkey-load Deployment sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$VALKEY_LOAD"
  [ "$status" -eq 0 ]
}

@test "valkey-load Deployment drops ALL capabilities" {
  run grep -q '\- ALL' "$VALKEY_LOAD"
  [ "$status" -eq 0 ]
}
