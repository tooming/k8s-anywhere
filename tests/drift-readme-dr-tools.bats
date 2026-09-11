#!/usr/bin/env bats
# Tests for readme-check.sh's section 2b: docs/DR.md carries its own copy of
# the preflight tool list (a `# check tools (brew install: ...)` comment on its
# `make preflight` line), separate from README.md's own brew-install line that
# section 2 already checks. Found live 2026-09-11: this second copy had
# silently drifted (missing docker/kubectl/terraform) with nothing catching
# it — see tests/drift-detectors.bats's own header for why new drift-check
# scopes land in their own tests/drift-<scope>.bats file rather than growing
# that frozen one.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/readme-check"
}

@test "readme-check: passes when docs/DR.md's tool list is in sync (in-sync fixture)" {
  run env READMECHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
}

@test "readme-check: fails when docs/DR.md's preflight tool list is missing a REQUIRED_TOOLS entry" {
  run env READMECHECK_ROOT="$FIX/dr-md-drift" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"helm"* ]]
  [[ "$output" == *"docs/DR.md"* ]]
}

@test "readme-check: skips the docs/DR.md check cleanly when the file doesn't exist" {
  run env READMECHECK_ROOT="$FIX/drift" bash "$REPO/scripts/readme-check.sh"
  # This fixture (make-target drift) has no docs/DR.md at all — the DR.md
  # section must not itself error or add noise; only the make-target drift
  # this fixture is actually testing should appear.
  [[ "$output" != *"docs/DR.md"* ]]
}

@test "readme-check: passes on the real repo's docs/DR.md tool list (post-fix)" {
  run bash "$REPO/scripts/readme-check.sh"
  [[ "$output" != *"docs/DR.md's preflight tool-list"* ]]
}
