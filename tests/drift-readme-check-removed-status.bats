#!/usr/bin/env bats
# Regression coverage for readme-check.sh's **Status.** Removed exemption —
# split into its own scope per the drift-detectors-tests-check convention
# (new coverage goes in its own tests/drift-<scope>.bats file, never appended
# to the frozen tests/drift-detectors.bats monolith).
#
# Found live 2026-09-07: ADR-0029's own Status line claimed its `keda-up`/
# `keda-down` Makefile targets "were deleted in the same change" as KEDA's
# removal, but they had actually survived as dead code (found + deleted the
# same cycle this test was added, see docs/done/2026-09-07-*keda*.md). Fixing
# that dead code then broke readme-check on the real repo: it only exempted
# **Superseded by** ADRs from its "every `make X` an ADR mentions must exist"
# rule, not **Removed** ones — even though a Removed ADR's historical prose
# is the identical "describes what was true when written, not current live
# state" shape. This guards that exemption.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/readme-check-removed-status"
}

@test "readme-check: does NOT flag a Removed-status ADR mentioning a since-deleted make target" {
  run env READMECHECK_ROOT="$FIX" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
}
