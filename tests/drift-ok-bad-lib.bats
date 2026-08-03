#!/usr/bin/env bats
# Tests for scripts/ok-bad-lib-check.sh — the drift guard that catches a
# scripts/*.sh file defining its own local, drift-setting bad() instead of
# sourcing the shared ok()/bad() pair in scripts/lib/colors.sh. See that
# script's header for the duplication this guards against recurring
# (~19 scripts each had their own byte-identical copy before this guard
# existed, found in the same duplication sweep as scripts/lib/yq.sh, issue
# #957).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/ok-bad-lib-check"
}

@test "ok-bad-lib-check: passes when no script defines its own drift-setting bad()" {
  run env OKBADLIB_ROOT="$FIX/in-sync" bash "$REPO/scripts/ok-bad-lib-check.sh"
  [ "$status" -eq 0 ]
}

@test "ok-bad-lib-check: does not flag a script with a legitimate no-side-effect bad()" {
  run env OKBADLIB_ROOT="$FIX/in-sync" bash "$REPO/scripts/ok-bad-lib-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"no-side-effect-check.sh"* ]]
}

@test "ok-bad-lib-check: fails when a script defines its own drift-setting bad()" {
  run env OKBADLIB_ROOT="$FIX/drift" bash "$REPO/scripts/ok-bad-lib-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dup-check.sh"* ]]
  [[ "$output" == *"scripts/lib/colors.sh"* ]]
}

@test "ok-bad-lib-check: a missing scripts/ directory is a clean no-op" {
  run env OKBADLIB_ROOT="$BATS_TEST_TMPDIR" bash "$REPO/scripts/ok-bad-lib-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

@test "ok-bad-lib-check: passes on the real repo scripts/" {
  run bash "$REPO/scripts/ok-bad-lib-check.sh"
  [ "$status" -eq 0 ]
}

# --- recurrence guard: the known former-duplicate callers now source it ----
@test "every drift-tracking script that used to define its own bad() sources scripts/lib/colors.sh" {
  for f in adr-chart-version-sync-check.sh adr-followup-check.sh adr-image-pin-sync-check.sh \
           context-doc-version-sync-check.sh docs-done-pr-link-check.sh dr-verify.sh \
           git-fixture-isolation-check.sh kustomize-orphan-check.sh lab-ui-check.sh lint.sh \
           networkpolicy-tests-check.sh readme-check.sh roadmap-check.sh routines-author-check.sh \
           routines-check.sh validate-terraform.sh yq-raw-check.sh yq-variant-guard-check.sh \
           yqs-lib-check.sh; do
    run grep -q 'lib/colors\.sh' "$REPO/scripts/$f"
    [ "$status" -eq 0 ]
  done
}
