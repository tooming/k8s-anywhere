#!/usr/bin/env bats
# Guard the ArgoCD cold-start resourcing (infra/modules/argocd/values.yaml).
# The initial `make up` sync storm renders+reconciles ~50 Applications at once.
# With the chart-default tiny CPU requests and 1s health-probe timeouts the
# repo-server and application-controller get CPU-starved, miss the probe, and
# kubelet crashloops them — ArgoCD never converges (ESO/garage/… stay Missing and
# the bootstrap scripts time out). These assert the hot components keep enough CPU
# and a relaxed probe timeout so a from-scratch make up can converge.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VALS="$REPO/infra/modules/argocd/values.yaml"
  # yqs(): yq-variant-robust scalar read (strips quoting differences). Bare yq
  # calls are forbidden in bats tests — see scripts/yq-raw-check.sh.
  load lib/yq
}

# "250m" -> 250 ; "1" -> 1000 (millicores)
cpu_millis() {
  case "$1" in
    *m) echo "${1%m}" ;;
    *)  echo $(( ${1%.*} * 1000 )) ;;
  esac
}

@test "argocd values.yaml exists" {
  [ -f "$VALS" ]
}

@test "repo-server requests >= 200m CPU (survives the make up sync storm)" {
  run cpu_millis "$(yqs '.repoServer.resources.requests.cpu' "$VALS")"
  [ "$output" -ge 200 ]
}

@test "repo-server probes relax the chart-default 1s timeout" {
  [ "$(yqs '.repoServer.livenessProbe.timeoutSeconds' "$VALS")" -ge 3 ]
  [ "$(yqs '.repoServer.readinessProbe.timeoutSeconds' "$VALS")" -ge 3 ]
}

@test "application-controller requests >= 200m CPU" {
  run cpu_millis "$(yqs '.controller.resources.requests.cpu' "$VALS")"
  [ "$output" -ge 200 ]
}

@test "application-controller readiness relaxes the chart-default 1s timeout" {
  [ "$(yqs '.controller.readinessProbe.timeoutSeconds' "$VALS")" -ge 3 ]
}
