#!/usr/bin/env bats
# Tests for the probe-timeout-sanity drift check (scripts/probe-timeout-check.sh) —
# its own file per the tests/drift-detectors.bats convention (new drift-check
# coverage goes in its own tests/drift-<scope>.bats file, never appended to that
# now-frozen monolith). See probe-timeout-check.sh's header comment for the
# 2026-08-11 multi-component incident this guards against.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/probe-timeout-check"
}

# --- structural walk: explicit probes in raw manifests + chart valuesObjects -----

@test "probe-timeout-check: passes when every explicit probe has timeoutSeconds >= 5" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/in-sync" PROBETIMEOUTCHECK_REQUIRED="" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"3 explicit probe"* ]]
}

@test "probe-timeout-check: FAILS on a raw manifest's probe with timeoutSeconds unset" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/drift-unset" PROBETIMEOUTCHECK_REQUIRED="" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad.yaml"* ]]
  [[ "$output" == *"timeoutSeconds unset"* ]]
}

@test "probe-timeout-check: FAILS on a chart valuesObject override with timeoutSeconds too tight" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/drift-tight" PROBETIMEOUTCHECK_REQUIRED="" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad.yaml"* ]]
  [[ "$output" == *"timeoutSeconds: 1"* ]]
}

@test "probe-timeout-check: a values-only override with no handler key still counts (not silently skipped)" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/in-sync" PROBETIMEOUTCHECK_REQUIRED="" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 0 ]
  # in-sync/gitops/good.yaml has 2 raw-manifest probes + 1 handler-less chart
  # override (webhook.readinessProbe: timeoutSeconds: 15) = 3 total.
  [[ "$output" == *"3 explicit probe"* ]]
}

# --- required-presence registry: catches silent deletion of a values-only fix ----

@test "probe-timeout-check: FAILS when a registered override is deleted entirely" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/required-missing" \
          PROBETIMEOUTCHECK_REQUIRED="gitops/widget.yaml|spec.source.helm.valuesObject.webhook.livenessProbe" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING"* ]]
  [[ "$output" == *"reverted"* ]]
}

@test "probe-timeout-check: passes when a registered override is present and compliant" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/required-present" \
          PROBETIMEOUTCHECK_REQUIRED="gitops/widget.yaml|spec.source.helm.valuesObject.webhook.livenessProbe" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 registered override"* ]]
}

@test "probe-timeout-check: passes on the real repo (gitops/ + infra/), registry included" {
  run bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-check: PROBETIMEOUTCHECK_FILES scopes the structural walk to one file" {
  run env PROBETIMEOUTCHECK_ROOT="$FIX/drift-unset" PROBETIMEOUTCHECK_REQUIRED="" \
          PROBETIMEOUTCHECK_FILES="gitops/bad.yaml" \
          bash "$REPO/scripts/probe-timeout-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad.yaml"* ]]
}
