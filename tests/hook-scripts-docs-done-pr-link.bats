#!/usr/bin/env bats
# Coverage for scripts/docs-done-pr-link-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "docs-done-pr-link-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/docs-done-pr-link-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "docs-done-pr-link-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/docs-done-pr-link-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "docs-done-pr-link-sync-hook: a real docs/done/ file (currently clean) exits 0" {
  run bash "$REPO/scripts/docs-done-pr-link-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/done/2026-07-28-argocd-chart-bump-9-7-1-to-10-2-1.md")"
  [ "$status" -eq 0 ]
}

@test "docs-done-pr-link-sync-hook: a docs/done/ file with an unresolved placeholder exits 2" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/docs/done"
  {
    echo "# fixture"
    echo
    echo "## PR"
    echo
    echo "(filled in after PR creation)"
  } >"$BATS_TEST_TMPDIR/fixture/docs/done/2026-01-01-fixture.md"
  run env DOCSDONEPRCHECK_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/docs-done-pr-link-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/docs/done/2026-01-01-fixture.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"unresolved '## PR' placeholder"* ]]
}
