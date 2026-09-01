#!/usr/bin/env bats
# Clusterless structural check: ack-s3 chart-pin recurrence guard, mirroring the
# existing pin-assertion pattern (cilium.bats, envoy-gateway.bats, etc.).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ACK_S3="$REPO/gitops/platform/ack-s3.yaml"
}

@test "ack-s3 Application file exists" {
  [ -f "$ACK_S3" ]
}

@test "ack-s3 Application pins chart version 1.11.0 (adds IgnoreFieldDrift feature gate)" {
  run grep -q 'targetRevision: 1.11.0' "$ACK_S3"
  [ "$status" -eq 0 ]
}

@test "ack-s3 Application does not pin the stale 1.10.0 version" {
  run grep -q 'targetRevision: 1.10.0' "$ACK_S3"
  [ "$status" -ne 0 ]
}

@test "ack-s3 Application does not pin the stale 1.9.0 version" {
  run grep -q 'targetRevision: 1.9.0' "$ACK_S3"
  [ "$status" -ne 0 ]
}

@test "ack-s3 Application does not pin the stale 1.8.2 version" {
  run grep -q 'targetRevision: 1.8.2' "$ACK_S3"
  [ "$status" -ne 0 ]
}
