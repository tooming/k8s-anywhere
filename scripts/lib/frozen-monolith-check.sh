# Shared implementation for the repo's "frozen monolith" bats-test drift
# checks (securitycontext-tests-check.sh, drift-detectors-tests-check.sh,
# hook-scripts-coverage-tests-check.sh) — sourced, not executed. Each thin
# wrapper resolves its own *_TESTS_ROOT env var, then calls
# frozen_monolith_check with its own file/snapshot/label.
# (observability-tests-check.sh was a fourth consumer, removed 2026-09-06
# alongside the monolith it guarded, tests/observability.bats — ADR-0041,
# observability stack removed with no replacement.)
#
# Why shared: these ~40-line scripts were independently copy-pasted from
# each other every time a new monolith got frozen (CLAUDE.md's
# bugfix-recurrence rule already demands a mechanical guard per monolith;
# this closes the matching "duplicated guard implementation" gap, mirroring
# the earlier colors.sh/hook-payload.sh extractions — same rationale: a
# future tweak to the snapshot-diff logic now needs one edit, and the next
# monolith to freeze is a 5-line wrapper, not another 40-line copy).
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Args: $1 bats file path, $2 snapshot path, $3 `make` mark-target name,
# $4 where NEW tests should go instead (for the diagnostic), $5 label used in
# messages (typically the bats file's repo-relative path).
frozen_monolith_check() {
  local file="$1" snap="$2" mark_target="$3" scope_hint="$4" label="$5"
  local drift=0
  bad(){ printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }

  [ -f "$file" ] || { echo "no $label — nothing to check"; return 0; }

  # The frozen baseline: the sorted set of @test titles in the monolith.
  titles(){ grep -oE '^@test "[^"]*"' "$1" | sort; }

  if [ ! -f "$snap" ]; then
    bad "missing snapshot $snap — run: make $mark_target"
  elif ! diff -q <(titles "$file") "$snap" >/dev/null 2>&1; then
    bad "$label is FROZEN but its @test set changed:"
    diff "$snap" <(titles "$file") | sed 's/^/      /' || true
    printf '      %s\n' "→ Add NEW tests in $scope_hint (not the monolith)."
    printf '      %s\n' "→ If you intentionally renamed/edited a monolith test: make $mark_target"
  fi

  [ "$drift" -eq 0 ] && printf '  %s✓%s %s frozen (new scopes go in %s)\n' "$G" "$Z" "$label" "$scope_hint"
  return "$drift"
}
