#!/usr/bin/env bats
# Tests for the yq-variant-portability drift checks — split out of the
# now-frozen tests/drift-detectors.bats monolith (see that file's header
# comment) into their own scope, per the drift-detectors-tests-check
# convention: new drift-check coverage goes in its own tests/drift-<scope>.bats
# file. Grouped together here because all three checks guard the same class of
# bug: mikefarah/yq (Go) and kislyuk/python-yq (jq wrapper) disagree on syntax
# (bare `yq` calls, `-o=json`, `tag==""`), and a script/test written against
# one variant silently produces false-negatives/false-positives on the other
# (this bit mimir-readonly-root-check.sh, chore/fix-mimir-ci-check-yq-compat).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- yq-raw-check --------------------------------------------------------------
@test "yq-raw-check: passes when no bats test calls yq directly" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/in-sync" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 0 ]
}

@test "yq-raw-check: fails when a bats test uses a bare yq call" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/drift" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bare 'yq'"* ]]
}

@test "yq-raw-check: passes on the real repo tests/" {
  run bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 0 ]
}

# --- yq-variant-guard-check ------------------------------------------------------
@test "yq-variant-guard-check: passes when a mikefarah-only-syntax script calls require_mikefarah_yq" {
  run env YQVARIANTGUARD_ROOT="$FIX/yq-variant-guard-check/in-sync" bash "$REPO/scripts/yq-variant-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "yq-variant-guard-check: fails when a mikefarah-only-syntax script has no guard" {
  run env YQVARIANTGUARD_ROOT="$FIX/yq-variant-guard-check/drift" bash "$REPO/scripts/yq-variant-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unguarded-check.sh"* ]]
  [[ "$output" == *"require_mikefarah_yq"* ]]
}

@test "yq-variant-guard-check: passes on the real repo scripts/" {
  run bash "$REPO/scripts/yq-variant-guard-check.sh"
  [ "$status" -eq 0 ]
}

# --- yq variant portability guard -----------------------------------------------
# mikefarah/yq (Go) and kislyuk/python-yq (jq wrapper) disagree on -o=json and
# tag==""  syntax. Scripts using mikefarah-only flags produce empty output on a
# kislyuk/python-yq installation (errors silently swallowed by 2>/dev/null),
# turning assertions into false-negatives or false-positives. This bit the
# mimir-readonly-root-check.sh (chore/fix-mimir-ci-check-yq-compat). Use
# python3/PyYAML instead (portable; already the fix in that script).
@test "no check script uses yq -o=json (mikefarah-only flag, breaks on kislyuk/python-yq)" {
  run grep -rl 'yq -o=json' "$REPO/scripts/"
  # grep exits 1 when no files match — that is the passing condition
  [ "$status" -eq 1 ]
}
