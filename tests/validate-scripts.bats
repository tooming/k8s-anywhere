#!/usr/bin/env bats
# Clusterless structural + behavioral tests for the three quality-gate scripts
# that had zero bats coverage: scripts/validate-kustomize.sh,
# scripts/validate-manifests.sh, scripts/validate-terraform.sh. All three are
# wired into `make ci` (the drift/manifests/kustomize/terraform CI jobs) and
# gate every PR — until now nothing caught an accidental regression in their
# CI-required-vs-local-skip behavior (a dropped `${CI:-}` check would silently
# turn a required CI gate into an always-green no-op). These tests exercise the
# real "tool not installed" path directly (none of kustomize/kubeconform/
# terraform are assumed present in the test environment) rather than mocking —
# no running cluster or network access required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VALKUSTOMIZE="$REPO/scripts/validate-kustomize.sh"
  VALMANIFESTS="$REPO/scripts/validate-manifests.sh"
  VALTERRAFORM="$REPO/scripts/validate-terraform.sh"
  MAKEFILE="$REPO/Makefile"
  # Strip any locally-installed validators from PATH so every test exercises
  # the real "tool not installed" branch deterministically, regardless of what
  # happens to be on the host running the suite.
  STRIPPED_PATH="$(printf '%s' "$PATH" | tr ':' '\n' | while read -r d; do
    [ -x "$d/kustomize" ] && continue
    [ -x "$d/kubeconform" ] && continue
    [ -x "$d/terraform" ] && continue
    printf '%s:' "$d"
  done)"
}

# --- scripts/validate-kustomize.sh -------------------------------------------
@test "validate-kustomize.sh exists" {
  [ -f "$VALKUSTOMIZE" ]
}

@test "validate-kustomize.sh is executable" {
  [ -x "$VALKUSTOMIZE" ]
}

@test "validate-kustomize.sh skips (exit 0) locally when kustomize is not installed" {
  run env PATH="$STRIPPED_PATH" bash "$VALKUSTOMIZE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping"* ]]
}

@test "validate-kustomize.sh FAILS (exit 1) in CI when kustomize is not installed" {
  run env PATH="$STRIPPED_PATH" CI=true bash "$VALKUSTOMIZE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required in CI"* ]]
}

@test "validate-kustomize.sh builds with LoadRestrictionsNone (cross-directory refs are allowed)" {
  run grep -q -- '--load-restrictor LoadRestrictionsNone' "$VALKUSTOMIZE"
  [ "$status" -eq 0 ]
}

@test "validate-kustomize.sh walks every kustomization.yaml under gitops/" {
  run grep -q "find \"\$ROOT/gitops\" -name 'kustomization.yaml'" "$VALKUSTOMIZE"
  [ "$status" -eq 0 ]
}

# --- scripts/validate-manifests.sh -------------------------------------------
@test "validate-manifests.sh exists" {
  [ -f "$VALMANIFESTS" ]
}

@test "validate-manifests.sh is executable" {
  [ -x "$VALMANIFESTS" ]
}

@test "validate-manifests.sh skips (exit 0) locally when kubeconform is not installed" {
  run env PATH="$STRIPPED_PATH" bash "$VALMANIFESTS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping"* ]]
}

@test "validate-manifests.sh FAILS (exit 1) in CI when kubeconform is not installed" {
  run env PATH="$STRIPPED_PATH" CI=true bash "$VALMANIFESTS"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required in CI"* ]]
}

@test "validate-manifests.sh ignores missing CRD schemas rather than failing on them" {
  run grep -q -- '-ignore-missing-schemas' "$VALMANIFESTS"
  [ "$status" -eq 0 ]
}

@test "validate-manifests.sh only fails the gate on Invalid, not on schema-fetch Errors" {
  # Regression guard: a schema-download rate-limit/timeout (kubeconform's
  # "Errors" count) must never fail the gate — only an actually-invalid
  # manifest ("Invalid" count) may. See the script's own header comment.
  run grep -q 'schema(s) failed to download' "$VALMANIFESTS"
  [ "$status" -eq 0 ]
  run grep -q 'if \[ -n "${errors:-}" \] && \[ "\$errors" -gt 0 \]' "$VALMANIFESTS"
  [ "$status" -eq 0 ]
  run grep -q 'if \[ -z "${invalid:-}" \] || \[ "\$invalid" -gt 0 \]' "$VALMANIFESTS"
  [ "$status" -eq 0 ]
}

# --- scripts/validate-terraform.sh -------------------------------------------
@test "validate-terraform.sh exists" {
  [ -f "$VALTERRAFORM" ]
}

@test "validate-terraform.sh is executable" {
  [ -x "$VALTERRAFORM" ]
}

@test "validate-terraform.sh skips (exit 0) locally when terraform is not installed" {
  run env PATH="$STRIPPED_PATH" bash "$VALTERRAFORM"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping"* ]]
}

@test "validate-terraform.sh FAILS (exit 1) in CI when terraform is not installed" {
  run env PATH="$STRIPPED_PATH" CI=true bash "$VALTERRAFORM"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required in CI"* ]]
}

@test "validate-terraform.sh checks fmt across the whole infra/ tree" {
  run grep -q -- 'terraform fmt -check -recursive infra/' "$VALTERRAFORM"
  [ "$status" -eq 0 ]
}

@test "validate-terraform.sh treats an unreachable provider registry as a local skip, not a hard failure" {
  run grep -q 'init failed (provider registry unreachable?) — skipping validate' "$VALTERRAFORM"
  [ "$status" -eq 0 ]
}

@test "validate-terraform.sh requires tflint in CI but only skips it locally" {
  run grep -q 'tflint not installed (required in CI)' "$VALTERRAFORM"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring -----------------------------------------------------------
@test "Makefile ci target invokes all three validate scripts" {
  run grep -A20 '^ci:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validate-kustomize.sh"* ]]
  [[ "$output" == *"validate-manifests.sh"* ]]
  [[ "$output" == *"validate-terraform.sh"* ]]
}

@test "Makefile validate target invokes validate-manifests.sh and validate-terraform.sh" {
  run grep -A3 '^validate:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validate-manifests.sh"* ]]
  [[ "$output" == *"validate-terraform.sh"* ]]
}
