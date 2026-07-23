#!/usr/bin/env bats
# Tests for scripts/mimir-readonly-root-check.sh — split out of the now-frozen
# tests/drift-detectors.bats monolith (see that file's header comment) into its
# own scope, per the drift-detectors-tests-check convention: new drift-check
# coverage goes in its own tests/drift-<scope>.bats file.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- mimir-readonly-root-check -------------------------------------------------
@test "mimir-readonly-root-check: passes when every write path is on a writable mount" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/in-sync" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 0 ]
}

@test "mimir-readonly-root-check: FAILS when activity_tracker.filepath is unset (read-only-root default)" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/drift" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"writable mount"* ]]
}

@test "mimir-readonly-root-check: FAILS when the Deployment has zero writable (emptyDir/PVC) volumeMounts" {
  # Regression for a real bug: mapfile read the check's empty-set output as one
  # empty-string array element (not zero), which made under_writable()'s "$m"/*
  # glob (m="") match literally any absolute path -- silently reporting every
  # write path as "writable" instead of catching a Deployment with no writable
  # mounts at all. Fixed by only printing the mount list when it's non-empty.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/no-writable-mounts" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"declares no writable"* ]]
}

@test "mimir-readonly-root-check: FAILS when the ConfigMap has no data[\"mimir.yaml\"] key" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/no-configmap-data" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *'no data["mimir.yaml"]'* ]]
}

@test "mimir-readonly-root-check: FAILS when a required setting is set but not under a writable mount" {
  # Distinct branch from "unset" above: ruler.rule_path IS set here, just to a
  # read-only (configMap) mount instead of a writable one.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/required-not-writable" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ruler.rule_path (/etc/mimir/ruler) is not under a writable mount"* ]]
}

@test "mimir-readonly-root-check: FAILS when an arbitrary config path lands off the writable mounts" {
  # Exercises the step-2 generic "/..." path scan (not one of the two hardcoded
  # REQUIRED settings) -- compactor.data_dir here, an ordinary absolute value.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/arbitrary-path-not-writable" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"config path /etc/mimir/compactor is not under a writable mount"* ]]
}

@test "mimir-readonly-root-check: passes on the real repo mimir manifests" {
  run bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 0 ]
}
