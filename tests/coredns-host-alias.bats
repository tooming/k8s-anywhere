#!/usr/bin/env bats
# Clusterless structural tests for scripts/coredns-host-alias.sh, which manages two
# independent rewrites in the coredns-custom ConfigMap (kube-system): host.k3d.internal
# (docker host gateway, needed for ArgoCD's Forgejo repoURL) and *.127.0.0.1.nip.io
# (Traefik's in-cluster Service, ADR-0040 — needed by any in-cluster client resolving
# a lab hostname — found live-patched out-of-band in PR #1323/issue #633). No running
# cluster required: these tests verify declared structure/behaviour only, never execute
# docker/kubectl against a live target.

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

@test "coredns-host-alias.sh accepts host-alias and nip-io-rewrite modes, defaulting to host-alias" {
  run grep -q 'MODE="\${1:-host-alias}"' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'host-alias | nip-io-rewrite)' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh host-alias mode fails clearly when the docker network gateway can't be resolved" {
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
  run grep -q 'host-k3d-internal\\.server' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'host.k3d.internal:53' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh is idempotent — skips the apply when both keys already match" {
  run grep -q 'already up to date' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'NEW_HOST_ALIAS.*=.*OLD_HOST_ALIAS' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'NEW_NIPIO.*=.*OLD_NIPIO' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh restarts CoreDNS and waits for the rollout" {
  run grep -q 'rollout restart deploy/coredns' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'rollout status deploy/coredns' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh nip-io-rewrite mode targets Traefik's well-known Service (ADR-0040, no owning-gateway label discovery needed)" {
  run grep -q 'TRAEFIK_NS=kube-system' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'TRAEFIK_SVC=traefik' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'gateway.envoyproxy.io' "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "coredns-host-alias.sh nip-io-rewrite mode polls with a budget instead of failing on the first check" {
  run grep -q 'COREDNS_NIPIO_WAIT:-300' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'until kubectl -n "\$TRAEFIK_NS" get svc "\$TRAEFIK_SVC"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh rewrites *.127.0.0.1.nip.io to Traefik's Service via the nip-io-rewrite.server key" {
  run grep -q 'nip-io-rewrite\\.server' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'rewrite name regex (\.\*)\\\.127\\\.0\\\.0\\\.1\\\.nip\\\.io' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'svc.cluster.local' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "coredns-host-alias.sh always includes both ConfigMap keys in the same apply, carrying the untouched mode's value forward" {
  # the exact clobbering pitfall this script exists to avoid: a `kubectl apply`
  # that only sets one data key would delete the other on next apply.
  run grep -q 'NEW_HOST_ALIAS="\$OLD_HOST_ALIAS"' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q 'NEW_NIPIO="\$OLD_NIPIO"' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q -- '--from-literal="host-k3d-internal.server=\$NEW_HOST_ALIAS"' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q -- '--from-literal="nip-io-rewrite.server=\$NEW_NIPIO"' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "Makefile declares both coredns-host-alias and coredns-nip-io-rewrite targets" {
  run grep -q '^coredns-host-alias:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  run grep -q '^coredns-nip-io-rewrite:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "make up runs coredns-nip-io-rewrite after root-app (Traefik's Service needs a moment to appear on cluster boot)" {
  run bash -c "sed -n '/^up:/,/^\.PHONY: down/p' '$REPO/Makefile' | grep -n 'root-app\\|coredns-nip-io-rewrite'"
  [ "$status" -eq 0 ]
  root_line="$(echo "$output" | grep 'root-app' | head -1 | cut -d: -f1)"
  nipio_line="$(echo "$output" | grep 'coredns-nip-io-rewrite' | head -1 | cut -d: -f1)"
  [ -n "$root_line" ]
  [ -n "$nipio_line" ]
  [ "$nipio_line" -gt "$root_line" ]
}
