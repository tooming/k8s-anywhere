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

# "768Mi" -> 768 ; "2Gi" -> 2048
mem_mi() {
  case "$1" in
    *Gi) echo $(( ${1%Gi} * 1024 )) ;;
    *Mi) echo "${1%Mi}" ;;
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

# Found 2026-07-24 (#632 investigation): with no explicit controller memory
# limit, the argocd namespace's `standard-limits` LimitRange (gitops/governance/
# argocd) silently filled in its 512Mi container default — identical to the
# request, so any reconcile spike above 512Mi (routine at 100+ Applications)
# OOMKilled the controller in seconds, crashlooping it indefinitely with every
# Application stuck at health "Unknown". An explicit limit here is the only way
# to keep this off the LimitRange's low default as the Application count grows.
@test "application-controller sets an explicit memory limit (does not fall back to the namespace LimitRange default)" {
  local limit
  limit="$(yqs '.controller.resources.limits.memory' "$VALS")"
  [ -n "$limit" ]
  [ "$limit" != "null" ]
}

@test "application-controller memory limit >= 1Gi (512Mi LimitRange default OOMKilled it at 124 Applications)" {
  run mem_mi "$(yqs '.controller.resources.limits.memory' "$VALS")"
  [ "$output" -ge 1024 ]
}
