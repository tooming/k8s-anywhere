#!/usr/bin/env bats
# Tests for scripts/docs-done-pr-link-check.sh — the drift guard that catches a
# docs/done/*.md file whose "## PR" section never got backfilled with the real
# PR link after the PR that shipped it actually opened. See that script's
# header for the 38-file backfill (2026-07-28) this guards against recurring.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures/docs-done-pr-link-check"
}

@test "docs-done-pr-link-check: passes when every docs/done/ file has a real PR link" {
  run env DOCSDONEPRCHECK_ROOT="$FIX/in-sync" bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 0 ]
}

@test "docs-done-pr-link-check: fails on the HTML-comment placeholder shape" {
  run env DOCSDONEPRCHECK_ROOT="$FIX/drift-html-comment" bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unresolved '## PR' placeholder"* ]]
}

@test "docs-done-pr-link-check: fails on the bare-parenthetical placeholder shape" {
  run env DOCSDONEPRCHECK_ROOT="$FIX/drift-parenthetical" bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"2026-01-01-example.md"* ]]
}

@test "docs-done-pr-link-check: fails on the branch-ref placeholder shape" {
  run env DOCSDONEPRCHECK_ROOT="$FIX/drift-branch-ref" bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 1 ]
}

@test "docs-done-pr-link-check: a missing docs/done/ directory is a clean no-op" {
  run env DOCSDONEPRCHECK_ROOT="$FIX/no-docs-done-dir" bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

@test "docs-done-pr-link-check: passes on the real repo's docs/done/ (post-backfill)" {
  run bash "$REPO/scripts/docs-done-pr-link-check.sh"
  [ "$status" -eq 0 ]
}
