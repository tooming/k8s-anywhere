#!/usr/bin/env bats
# Clusterless structural tests for the k3d containerd registry mirror that
# redirects in-cluster pulls of harbor.127.0.0.1.nip.io to Harbor's real
# in-cluster Service. No live k3d cluster needed -- pure text assertions
# against the bootstrap template. Mirrors tests/k3s-version-pin.bats's
# file-content-assertion pattern.
#
# Background: nip.io resolves <anything>.<IP>.nip.io to the literal <IP> in
# the hostname regardless of where the DNS query originates, so
# harbor.127.0.0.1.nip.io means "this pod's own loopback" from inside any
# pod -- breaking in-cluster pulls and Kargo Warehouse digest discovery
# (issue #633). The mirror below fixes that without changing what the
# hostname means anywhere outside the cluster.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  K3D_CONFIG="$REPO/infra/modules/k3d-cluster/k3d-config.yaml.tftpl"
}

@test "k3d-cluster module declares a top-level registries block" {
  run grep -qE '^registries:$' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
}

@test "the registry mirror names harbor.127.0.0.1.nip.io" {
  run grep -q '"harbor.127.0.0.1.nip.io":' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
}

@test "the mirror endpoint targets Harbor's real in-cluster Service over plain HTTP" {
  run grep -q 'http://harbor.harbor.svc.cluster.local' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
}

@test "the mirror endpoint is NOT https (Harbor's minimal profile has TLS disabled, ADR-0024)" {
  run grep -q 'https://harbor.harbor.svc.cluster.local' "$K3D_CONFIG"
  [ "$status" -ne 0 ]
}

@test "recurrence guard: the mirror endpoint does not point back at 127.0.0.1 (the bug this fixes)" {
  run grep -A2 '"harbor.127.0.0.1.nip.io":' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
  [[ "$output" != *"endpoint"*"127.0.0.1"* ]]
}

@test "registries block sits alongside the existing unconditional ports: block (no conditional)" {
  # The registries: block must not be nested inside the disable_traefik/
  # disable_default_cni conditional -- it should always render.
  run grep -B20 '^registries:$' "$K3D_CONFIG"
  [ "$status" -eq 0 ]
  [[ "$output" != *'%{ if'* ]]
}
