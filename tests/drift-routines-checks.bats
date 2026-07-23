#!/usr/bin/env bats
# Tests for the routines-governance drift checks — split out of the now-frozen
# tests/drift-detectors.bats monolith (see that file's header comment) into
# its own scope, per the drift-detectors-tests-check convention: new
# drift-check coverage goes in its own tests/drift-<scope>.bats file. Grouped
# together here because both guard routines/routines.yaml staying honest and
# correctly tracked (who may edit it, and that drift on it is actually
# detected).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- routines-author-check --------------------------------------------------------
# The executor (auto/* branch, cloud "Claude <noreply@anthropic.com>" commits) has
# no RemoteTrigger tool, so it can't apply a routines.yaml change to the live
# trigger. This guard fails when an executor-authored change edits routines.yaml.
# Branch and changed-file list are injected via env so the logic is testable
# without a live git history.
#
# Since the 2026-07-15 pointer architecture, routines/*.prompt.md files are read
# live every run and never baked into a trigger — editing one carries zero
# live-drift risk, so this guard no longer protects them at all (any session,
# including the executor, may edit them freely). Only routines.yaml still drives
# live trigger state via the API, so it remains the one protected file.

@test "routines-author-check: passes when an auto/* change edits a routine prompt (no longer baked into any trigger)" {
  run env ROUTINES_AUTHOR_BRANCH="auto/foo" \
          ROUTINES_AUTHOR_FILES=$'routines/executor.prompt.md\ngitops/x.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: FAILS when an auto/* change edits routines.yaml" {
  run env ROUTINES_AUTHOR_BRANCH="auto/bar" \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"routines.yaml"* ]]
}

@test "routines-author-check: passes when an auto/* change touches no routine files" {
  run env ROUTINES_AUTHOR_BRANCH="auto/foo" \
          ROUTINES_AUTHOR_FILES=$'gitops/x.yaml\ndocs/done/2026-06-25-foo.md' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: passes when an INTERACTIVE branch edits routines.yaml (it can apply)" {
  run env ROUTINES_AUTHOR_BRANCH="chore/edit-routines" \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: FAILS on a cloud-authored routines.yaml edit even off the auto/* prefix" {
  run env ROUTINES_AUTHOR_BRANCH="chore/sneaky" \
          ROUTINES_AUTHOR_IS_CLOUD=1 \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cloud identity"* ]]
}

@test "routines-author-check: passes on the real repo (this branch makes no routine edits)" {
  run bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

# --- routines-check ----------------------------------------------------------------
# Regression: the file has always lived at routines/routines.yaml, but the script
# once globbed "$ROOT/routines.yaml" (no such file) so drift on it was silently
# never detected. Assert it's actually tracked now.
@test "routines-check: tracks routines/routines.yaml, not a nonexistent top-level path" {
  run bash "$REPO/scripts/routines-check.sh"
  [[ "$output" != *"routines.yaml is not in .routines-applied"* ]]
}
