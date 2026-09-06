#!/usr/bin/env bats
# scripts/garage-bootstrap.sh's s3manager-key seam (ADR-0039, Garage S3 browser UI).
#
# Found live 2026-09-06 (issue #633 rebuild session): the mimir-key + secret/garage/s3
# Vault write this script used to also do was removed 2026-09-06 (ADR-0041,
# observability stack removed with no replacement) — correctly, since Mimir is gone —
# but gitops/secrets/garage-s3-storage-externalsecret.yaml (s3manager's own
# ExternalSecret, unrelated to Mimir) still reads secret/garage/s3, so s3manager broke
# with SecretSyncedError on the first genuinely fresh bootstrap after that removal.
# velero.bats/harbor.bats already cover this script's velero-key/harbor-key seams;
# this file gives s3manager's the same coverage.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  GARAGE="$REPO/scripts/garage-bootstrap.sh"
}

@test "garage-bootstrap.sh creates the s3manager-key Garage access key" {
  run grep -q 's3manager-key' "$GARAGE"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh writes secret/garage/s3 to Vault (s3manager's ExternalSecret path)" {
  run grep -q 'secret/garage/s3' "$GARAGE"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh grants s3manager-key access to the buckets it creates" {
  run grep -q 'bucket allow --read --write velero --key s3manager-key' "$GARAGE"
  [ "$status" -eq 0 ]
  run grep -q 'bucket allow --read --write harbor-registry --key s3manager-key' "$GARAGE"
  [ "$status" -eq 0 ]
}

@test "gitops/secrets/garage-s3-storage-externalsecret.yaml still reads secret/garage/s3 (matches what garage-bootstrap.sh now writes)" {
  run grep -q 'key: garage/s3' "$REPO/gitops/secrets/garage-s3-storage-externalsecret.yaml"
  [ "$status" -eq 0 ]
}
