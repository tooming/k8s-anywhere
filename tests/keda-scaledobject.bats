#!/usr/bin/env bats
# Clusterless structural tests for the KEDA rabbitmq-load-scaler ScaledObject demo
# (ADR-0029 §"Scope & exceptions" ScaledObject-demo follow-up). Validates the
# TriggerAuthentication + ScaledObject manifests, the separate wave-7 Application that
# delivers them (sequenced after keda's wave-6 CRDs), the NetworkPolicy egress/ingress
# this cross-namespace poll requires, and the rabbitmq-load burst/drain timing that
# makes the demo actually observable. Per-scope file — not part of tests/keda.bats.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
  TA="$REPO/gitops/data/demo/keda-scaling/triggerauthentication.yaml"
  SO="$REPO/gitops/data/demo/keda-scaling/scaledobject.yaml"
  APP="$REPO/gitops/platform/data-demo-keda-scaling.yaml"
}

# --- TriggerAuthentication -----------------------------------------------------
@test "rabbitmq-trigger-auth TriggerAuthentication exists" {
  [ -f "$TA" ]
}

@test "rabbitmq-trigger-auth is in namespace data" {
  [ "$(yqs '.metadata.namespace' "$TA")" = "data" ]
}

@test "rabbitmq-trigger-auth reads username/password from the existing data-demo-creds Secret" {
  [ "$(yqs '.spec.secretTargetRef[0].parameter' "$TA")" = "username" ]
  [ "$(yqs '.spec.secretTargetRef[0].name' "$TA")" = "data-demo-creds" ]
  [ "$(yqs '.spec.secretTargetRef[0].key' "$TA")" = "rabbitmq-username" ]
  [ "$(yqs '.spec.secretTargetRef[1].parameter' "$TA")" = "password" ]
  [ "$(yqs '.spec.secretTargetRef[1].name' "$TA")" = "data-demo-creds" ]
  [ "$(yqs '.spec.secretTargetRef[1].key' "$TA")" = "rabbitmq-password" ]
}

# --- ScaledObject ---------------------------------------------------------------
@test "rabbitmq-load-scaler ScaledObject exists" {
  [ -f "$SO" ]
}

@test "rabbitmq-load-scaler is in namespace data" {
  [ "$(yqs '.metadata.namespace' "$SO")" = "data" ]
}

@test "rabbitmq-load-scaler targets the rabbitmq-load Deployment" {
  [ "$(yqs '.spec.scaleTargetRef.name' "$SO")" = "rabbitmq-load" ]
}

@test "rabbitmq-load-scaler bounds replicas 1..5 (demo, not a capacity plan)" {
  [ "$(yqs '.spec.minReplicaCount' "$SO")" = "1" ]
  [ "$(yqs '.spec.maxReplicaCount' "$SO")" = "5" ]
}

@test "rabbitmq-load-scaler uses the rabbitmq trigger on queue 'demo'" {
  [ "$(yqs '.spec.triggers[0].type' "$SO")" = "rabbitmq" ]
  [ "$(yqs '.spec.triggers[0].metadata.queueName' "$SO")" = "demo" ]
}

@test "rabbitmq-load-scaler polls the management API over HTTP at the real Service host" {
  [ "$(yqs '.spec.triggers[0].metadata.host' "$SO")" = "http://rabbitmq.data.svc.cluster.local:15672" ]
  [ "$(yqs '.spec.triggers[0].metadata.protocol' "$SO")" = "http" ]
}

@test "rabbitmq-load-scaler queueLength threshold is 1 (any backlog beyond one message scales up)" {
  [ "$(yqs '.spec.triggers[0].metadata.queueLength' "$SO")" = "1" ]
}

@test "rabbitmq-load-scaler references the rabbitmq-trigger-auth TriggerAuthentication" {
  [ "$(yqs '.spec.triggers[0].authenticationRef.name' "$SO")" = "rabbitmq-trigger-auth" ]
}

# --- data-demo-keda-scaling Application (wave 7, after keda's wave-6 CRDs) -----
@test "data-demo-keda-scaling Application exists" {
  [ -f "$APP" ]
}

@test "data-demo-keda-scaling Application sources gitops/data/demo/keda-scaling" {
  run grep -q 'path: gitops/data/demo/keda-scaling' "$APP"
  [ "$status" -eq 0 ]
}

@test "data-demo-keda-scaling Application targets the data namespace" {
  [ "$(yqs '.spec.destination.namespace' "$APP")" = "data" ]
}

@test "data-demo-keda-scaling Application is auto-synced" {
  run grep -q 'automated:' "$APP"
  [ "$status" -eq 0 ]
}

@test "data-demo-keda-scaling Application runs at sync-wave 7 (after keda's wave-6 CRDs)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "7"' "$APP"
  [ "$status" -eq 0 ]
}

@test "the ScaledObject/TriggerAuthentication CRs are NOT sourced by the wave-4 data-demo Application" {
  run grep -q 'keda-scaling' "$REPO/gitops/platform/data-demo.yaml"
  [ "$status" -ne 0 ]
}

# --- NetworkPolicy: KEDA operator -> RabbitMQ management API -------------------
@test "allow-keda-egress-rabbitmq.yaml exists in keda/networkpolicy/" {
  [ -f "$REPO/gitops/keda/networkpolicy/allow-keda-egress-rabbitmq.yaml" ]
}

@test "keda kustomization references the rabbitmq egress allow file" {
  run grep -q 'allow-keda-egress-rabbitmq.yaml' "$REPO/gitops/keda/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-keda-egress-rabbitmq permits egress on TCP 15672 to the data namespace" {
  run grep -q 'port: 15672' "$REPO/gitops/keda/networkpolicy/allow-keda-egress-rabbitmq.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: data' "$REPO/gitops/keda/networkpolicy/allow-keda-egress-rabbitmq.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-rabbitmq-ingress in the data namespace now permits the keda namespace on TCP 15672" {
  run grep -q 'kubernetes.io/metadata.name: keda' "$REPO/gitops/data/networkpolicy/allow-rabbitmq-ingress.yaml"
  [ "$status" -eq 0 ]
}

# --- rabbitmq-load burst/drain timing (makes the demo actually observable) ----
@test "rabbitmq-load script publishes a burst of 5 messages per cycle" {
  run grep -q 'for i in 1 2 3 4 5; do' "$REPO/gitops/data/demo/rabbitmq-load.yaml"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load script holds the burst for 40s (longer than KEDA's default 30s pollingInterval)" {
  run grep -q 'sleep 40' "$REPO/gitops/data/demo/rabbitmq-load.yaml"
  [ "$status" -eq 0 ]
}

@test "rabbitmq-load script still drains via the queue get endpoint each cycle" {
  run grep -q 'XPOST "\$API/queues/%2f/\$Q/get"' "$REPO/gitops/data/demo/rabbitmq-load.yaml"
  [ "$status" -eq 0 ]
}
