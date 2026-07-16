#!/usr/bin/env bats
# Clusterless structural + behavioral tests for scripts/test.sh — the wrapper
# `make test` / `make ci` invoke to run this very bats suite. Same class of gap
# as tests/validate-scripts.bats and tests/lint-script.bats: it shares the
# local-skip-vs-CI-required pattern (bats not installed) with no coverage of its
# own until now — a dropped ${CI:-} check here would silently turn the CI `unit`
# job into an always-green no-op with nothing catching the regression.

setup_file() {
  # Shim only `bats` out of PATH (not the whole directory it lives in — package
  # managers commonly co-install bats alongside bash itself, e.g. apt → /usr/bin;
  # see tests/lint-script.bats for why stripping that directory wholesale breaks
  # the script with an unrelated "command not found" instead of exercising the
  # "tool not installed" branch this is meant to test). Built once per file.
  SHIM="$BATS_FILE_TMPDIR/shim-bin"
  mkdir -p "$SHIM"
  printf '%s' "$PATH" | tr ':' '\n' | while read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      base="$(basename "$f")"
      [ "$base" = "bats" ] && continue
      [ -e "$SHIM/$base" ] && continue
      ln -s "$f" "$SHIM/$base" 2>/dev/null || true
    done
  done
}

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TESTSH="$REPO/scripts/test.sh"
  MAKEFILE="$REPO/Makefile"
  STRIPPED_PATH="$BATS_FILE_TMPDIR/shim-bin"
}

@test "test.sh exists" {
  [ -f "$TESTSH" ]
}

@test "test.sh is executable" {
  [ -x "$TESTSH" ]
}

@test "test.sh skips (exit 0) locally when bats is not installed" {
  # -u CI: CI runners (including the one running this suite) set CI=true in the
  # ambient environment, which env FOO=bar alone does not clear.
  run env -u CI PATH="$STRIPPED_PATH" bash "$TESTSH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bats not installed"* ]]
  [[ "$output" == *"skipping unit tests"* ]]
}

@test "test.sh FAILS (exit 1) in CI when bats is not installed" {
  run env -u CI PATH="$STRIPPED_PATH" CI=true bash "$TESTSH"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bats not installed (required in CI)"* ]]
}

@test "test.sh execs bats against the tests/ directory when present" {
  # Not exercised end-to-end here (that would recursively run this entire
  # suite from within one of its own assertions) — a structural guard that the
  # happy path really does hand off to bats tests/, not some other path.
  run grep -q '^exec bats tests/$' "$TESTSH"
  [ "$status" -eq 0 ]
}

@test "test.sh runs from the repo root regardless of caller cwd" {
  run grep -q 'cd "\$ROOT" || exit 1' "$TESTSH"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring -----------------------------------------------------------
@test "Makefile test target invokes test.sh" {
  run grep -A1 '^test:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test.sh"* ]]
}

@test "Makefile ci target invokes test.sh" {
  run grep -A10 '^ci:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test.sh"* ]]
}
