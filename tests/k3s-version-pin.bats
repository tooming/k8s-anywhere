#!/usr/bin/env bats
# Clusterless structural tests for the k3s version pin (ADR-0030). Neither
# terraform apply nor a running cluster required -- pure text assertions against
# the bootstrap templates. Guards against a future bump updating one backend's
# pin and forgetting the other's (they use different tag formats: Docker Hub's
# hyphen vs. INSTALL_K3S_VERSION's "+").

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  K3D_CONFIG="$REPO/infra/modules/k3d-cluster/k3d-config.yaml.tftpl"
  CLOUD_INIT="$REPO/infra/modules/oracle-k3s-cluster/cloud-init.yaml"
}

@test "k3d-cluster module pins an explicit k3s image (not left to the CLI default)" {
  run grep -qE '^image: rancher/k3s:v[0-9]+\.[0-9]+\.[0-9]+-k3s[0-9]+$' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
}

@test "k3d-cluster pins k3s v1.36.3-k3s1 (Docker Hub tag format, ADR-0030)" {
  run grep -q 'image: rancher/k3s:v1.36.3-k3s1' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster cloud-init pins an explicit INSTALL_K3S_VERSION (not a bare get.k3s.io curl)" {
  run grep -qE 'INSTALL_K3S_VERSION=v[0-9]+\.[0-9]+\.[0-9]+\+k3s[0-9]+ sh -' "$CLOUD_INIT"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster pins k3s v1.36.3+k3s1 (INSTALL_K3S_VERSION tag format, ADR-0030)" {
  run grep -q 'INSTALL_K3S_VERSION=v1.36.3+k3s1 sh -' "$CLOUD_INIT"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster cloud-init no longer installs k3s with a bare, unpinned curl" {
  run grep -q '^  - curl -sfL https://get.k3s.io | sh -$' "$CLOUD_INIT"
  [ "$status" -ne 0 ]
}

@test "both backends pin the SAME k3s version (same numeric version, correct tag format each)" {
  k3d_ver="$(grep -oE 'rancher/k3s:v[0-9]+\.[0-9]+\.[0-9]+-k3s[0-9]+' "$K3D_CONFIG" | sed -E 's#.*v([0-9]+\.[0-9]+\.[0-9]+)-(k3s[0-9]+)#\1+\2#')"
  oracle_ver="$(grep -oE 'INSTALL_K3S_VERSION=v[0-9]+\.[0-9]+\.[0-9]+\+k3s[0-9]+' "$CLOUD_INIT" | sed -E 's#INSTALL_K3S_VERSION=v##')"
  [ -n "$k3d_ver" ]
  [ -n "$oracle_ver" ]
  [ "$k3d_ver" = "$oracle_ver" ]
}

@test "docs/decisions/context.md no longer shows the stale pre-pin k3s version" {
  run grep -q 'k3s v1.33.6' "$REPO/docs/decisions/context.md"
  [ "$status" -ne 0 ]
}

@test "docs/decisions/context.md documents the pinned k3s version" {
  run grep -q 'k3s v1.36.3+k3s1' "$REPO/docs/decisions/context.md"
  [ "$status" -eq 0 ]
}

@test "ADR-0030 (k3s version pin) document exists" {
  run sh -c "ls $REPO/docs/decisions/adr-0030-*.md"
  [ "$status" -eq 0 ]
}
