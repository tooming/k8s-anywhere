#!/usr/bin/env bats
# Clusterless structural tests for the add-default-runasnonroot Kyverno mutate
# ClusterPolicy (ADR-0019 defence-in-depth). This policy closes a real admission
# gap found by the Harbor migration (ADR-0024): goharbor/harbor 1.16.0 runs
# non-root (pod runAsUser:10000) with a compliant CONTAINER securityContext, but
# the chart never sets pod-level runAsNonRoot and exposes no override for it, so
# require-pod-security-restricted (which checks the POD level, ADR-0017) rejected
# every Harbor workload at admission. This mutate injects the missing field.
#
# Own file (not appended to tests/kyverno.bats) per the one-scope-one-file rule
# that keeps parallel PRs from colliding on a shared monolith's EOF.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
  P="$REPO/gitops/kyverno/policies/add-default-runasnonroot.yaml"
}

@test "add-default-runasnonroot ClusterPolicy file exists" {
  [ -f "$P" ]
}

@test "add-default-runasnonroot is a Kyverno ClusterPolicy" {
  [ "$(yqs '.kind' "$P")" = "ClusterPolicy" ]
  [ "$(yqs '.metadata.name' "$P")" = "add-default-runasnonroot" ]
}

@test "add-default-runasnonroot matches Pods" {
  [ "$(yqs '.spec.rules[0].match.any[0].resources.kinds[0]' "$P")" = "Pod" ]
}

@test "add-default-runasnonroot uses a mutate rule (not validate)" {
  [ "$(yqs '.spec.rules[0].mutate.patchStrategicMerge.spec.securityContext != null' "$P")" = "true" ]
}

@test "add-default-runasnonroot injects pod-level runAsNonRoot=true" {
  # The patch must land at spec.securityContext (POD level), matching where
  # require-pod-security-restricted checks it — not at container level.
  run grep -qE 'securityContext:' "$P"
  [ "$status" -eq 0 ]
  run grep -qE '\+\(runAsNonRoot\): true' "$P"
  [ "$status" -eq 0 ]
}

@test "add-default-runasnonroot only patches when the field is absent (conditional anchor)" {
  # +(runAsNonRoot) is Kyverno's add-if-absent anchor; a workload that already
  # sets runAsNonRoot (either value) must not be overwritten.
  run grep -q '+(runAsNonRoot)' "$P"
  [ "$status" -eq 0 ]
}

@test "add-default-runasnonroot only fires for a declared non-root UID (precondition guards root workloads)" {
  # preconditions gate on runAsUser > 0 declared at the pod level OR on the
  # first container, so root pods (runAsUser:0 or unset everywhere) are never
  # forced non-root.
  [ "$(yqs '.spec.rules[0].preconditions.any[0].operator' "$P")" = "GreaterThan" ]
  [ "$(yqs '.spec.rules[0].preconditions.any[0].value' "$P")" = "0" ]
  [ "$(yqs '.spec.rules[0].preconditions.any[1].operator' "$P")" = "GreaterThan" ]
  [ "$(yqs '.spec.rules[0].preconditions.any[1].value' "$P")" = "0" ]
  run grep -q 'runAsUser' "$P"
  [ "$status" -eq 0 ]
}

@test "add-default-runasnonroot also matches a container-level (not just pod-level) non-root UID" {
  # akuity/kargo has no pod-level securityContext knob at all — only a
  # per-component value that templates onto the CONTAINER. The precondition
  # must also key off spec.containers[0].securityContext.runAsUser for that
  # case. (A `[?...]` JMESPath filter over all containers was tried first and
  # verified live to silently never match under Kyverno's `{{ }}` evaluator —
  # containers[0] is the confirmed-working form; see the policy's comment.)
  run grep -q 'spec.containers\[0\].securityContext.runAsUser' "$P"
  [ "$status" -eq 0 ]
}

@test "add-default-runasnonroot excludes baseline/privileged carve-out namespaces" {
  # Same exclude set as require-pod-security-restricted: deliberately root-running
  # namespaces (vault, istio-system, tidb, …) must be skipped so their root
  # init/JVM containers are never forced runAsNonRoot.
  run grep -q 'pod-security.kubernetes.io/enforce' "$P"
  [ "$status" -eq 0 ]
  run grep -q 'baseline' "$P"
  [ "$status" -eq 0 ]
  run grep -q 'privileged' "$P"
  [ "$status" -eq 0 ]
}

@test "add-default-runasnonroot excludes the kube-system control-plane namespaces" {
  run grep -q 'kube-system' "$P"
  [ "$status" -eq 0 ]
}
