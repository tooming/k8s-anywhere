#!/usr/bin/env bats
# Tests for scripts/yqs-lib-check.sh — the drift guard that catches a
# scripts/*.sh file defining its own local yqs() helper instead of sourcing
# the one shared copy in scripts/lib/yq.sh. See that script's header for the
# duplication this guards against recurring
# (scripts/adr-chart-version-sync-check.sh and
# scripts/context-doc-version-sync-check.sh each had their own byte-identical
# copy before this guard existed).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/yqs-lib-check"
}

@test "yqs-lib-check: passes when no script defines its own yqs()" {
  run env YQSLIB_ROOT="$FIX/in-sync" bash "$REPO/scripts/yqs-lib-check.sh"
  [ "$status" -eq 0 ]
}

@test "yqs-lib-check: fails when a script defines its own yqs()" {
  run env YQSLIB_ROOT="$FIX/drift" bash "$REPO/scripts/yqs-lib-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"dup-check.sh"* ]]
  [[ "$output" == *"scripts/lib/yq.sh"* ]]
}

@test "yqs-lib-check: a missing scripts/ directory is a clean no-op" {
  run env YQSLIB_ROOT="$BATS_TEST_TMPDIR" bash "$REPO/scripts/yqs-lib-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

@test "yqs-lib-check: passes on the real repo scripts/" {
  run bash "$REPO/scripts/yqs-lib-check.sh"
  [ "$status" -eq 0 ]
}

# --- recurrence guard: the two known former-duplicate callers now source it ----
@test "adr-chart-version-sync-check.sh and context-doc-version-sync-check.sh source scripts/lib/yq.sh" {
  for f in adr-chart-version-sync-check.sh context-doc-version-sync-check.sh; do
    run grep -q 'lib/yq\.sh' "$REPO/scripts/$f"
    [ "$status" -eq 0 ]
  done
}
