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

# 2026-08-07: found repo-server crashlooping continuously for 24h+ with the old
# 5s timeout — its healthz handler was observed missing it by 0.0-0.4s under
# sustained host latency (not the cold-start CPU-throttling the original 5s was
# sized for), killing and restarting the only replica in an indefinite loop
# that never converges (every sync fails while it's down). >= 3 alone doesn't
# guard against regressing back to a value that's merely "relaxed" but still
# too tight for this host's actual latency profile.
@test "repo-server probes are generous enough to survive sustained host latency, not just the cold-start default" {
  [ "$(yqs '.repoServer.livenessProbe.timeoutSeconds' "$VALS")" -ge 10 ]
  [ "$(yqs '.repoServer.readinessProbe.timeoutSeconds' "$VALS")" -ge 10 ]
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

@test "docs/dependency-tree.md wave-0 row lists argocd-extras" {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  run grep -q 'argocd-extras (SSA-patches full PSA' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

@test "argocd-extras.yaml comment reflects the current (not superseded) PSA phase" {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  run grep -q 'Phase 1 warn/audit labels' "$REPO/gitops/platform/argocd-extras.yaml"
  [ "$status" -ne 0 ]
}
