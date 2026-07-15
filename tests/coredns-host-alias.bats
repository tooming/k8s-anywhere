#!/usr/bin/env bats
# Clusterless structural tests for scripts/coredns-host-alias.sh, which had zero
# coverage of its own behaviour (tests/cilium.bats only asserts its Makefile
# ordering relative to cilium-up). Wired into `make coredns-host-alias` / `make up`
# and required for ArgoCD's GitLab repoURL to resolve under Colima/Docker on macOS
# (see the script's own header comment). No running cluster required: these tests
# verify declared structure/behaviour only, never execute docker/kubectl against a
# live target.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/coredns-host-alias.sh"
}

@test "coredns-host-alias.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "coredns-host-alias.sh is executable" {
  [ -x "$SCRIPT" ]
}

@test "coredns-host-alias.sh fails clearly when the docker network gateway can't be resolved" {
  run grep -q 'could not resolve docker network' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'exit 1' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh targets the k3d-k8s-lab docker network" {
  run grep -q 'NET=k3d-k8s-lab' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh writes the coredns-custom ConfigMap in kube-system" {
  run grep -q 'NS=kube-system' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'configmap coredns-custom' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh aliases host.k3d.internal via the host-k3d-internal.server key" {
  run grep -q 'host-k3d-internal\.server' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'host.k3d.internal:53' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh is idempotent — skips the apply when the ConfigMap already matches" {
  run grep -q 'already up to date' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'CURRENT.*=.*DESIRED' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh restarts CoreDNS and waits for the rollout" {
  run grep -q 'rollout restart deploy/coredns' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'rollout status deploy/coredns' "$SCRIPT"
  [ "$status" -eq 0 ]
}
