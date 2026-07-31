#!/usr/bin/env bats
# Clusterless behavioral tests for scripts/lib/frozen-monolith-check.sh and
# scripts/lib/frozen-monolith-sync-hook.sh — the shared "frozen monolith"
# drift-check implementation backing four wrapper pairs
# (securitycontext/observability/drift-detectors/hook-scripts-coverage
# -tests-check.sh + -tests-sync-hook.sh). Unlike every other scripts/lib/*.sh
# extraction (colors.sh, hook-payload.sh, yq-variant.sh, budget-check.sh, each
# with its own <name>-lib.bats), these two had only transitive coverage via
# tests/drift-frozen-monolith-checks.bats exercising the four wrappers — never
# a direct test of the shared functions themselves. Mirrors
# tests/hook-payload-lib.bats's shape.
#
# NOTE: fixture bats files below are built with an `AT_TEST` placeholder,
# never a literal line-leading `@test`, and fixed up with `sed` afterwards.
# bats-core's own test-collection preprocessor scans every *.bats file
# (including this one) line-by-line for `^@test`, with no heredoc awareness —
# a literal `@test "..." {` inside one of this file's own heredocs gets
# collected as a bogus extra test of THIS file (confirmed locally: it throws
# "Duplicate test name(s)" / "unknown test name" errors). The placeholder
# sidesteps that entirely.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- existence + syntax -------------------------------------------------

@test "scripts/lib/frozen-monolith-check.sh exists" {
  [ -f "$REPO/scripts/lib/frozen-monolith-check.sh" ]
}

@test "scripts/lib/frozen-monolith-sync-hook.sh exists" {
  [ -f "$REPO/scripts/lib/frozen-monolith-sync-hook.sh" ]
}

@test "frozen-monolith-check.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/frozen-monolith-check.sh"
  [ "$status" -eq 0 ]
}

@test "frozen-monolith-sync-hook.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/frozen-monolith-sync-hook.sh"
  [ "$status" -eq 0 ]
}

@test "frozen-monolith-check.sh defines frozen_monolith_check()" {
  run grep -q "^frozen_monolith_check()" "$REPO/scripts/lib/frozen-monolith-check.sh"
  [ "$status" -eq 0 ]
}

@test "frozen-monolith-sync-hook.sh defines frozen_monolith_sync_hook()" {
  run grep -q "^frozen_monolith_sync_hook()" "$REPO/scripts/lib/frozen-monolith-sync-hook.sh"
  [ "$status" -eq 0 ]
}

# --- frozen_monolith_check() direct behavior -----------------------------

@test "frozen_monolith_check() passes when the bats file's @test titles match the snapshot" {
  source "$REPO/scripts/lib/frozen-monolith-check.sh"

  local bats_file="$BATS_TEST_TMPDIR/fixture-monolith.bats"
  local snap="$BATS_TEST_TMPDIR/.fixture-titles"
  cat >"$bats_file" <<'EOF'
#!/usr/bin/env bats
AT_TEST "alpha does a thing" {
  true
}
AT_TEST "beta does another thing" {
  true
}
EOF
  sed -i 's/^AT_TEST /@test /' "$bats_file"
  grep -oE '^@test "[^"]*"' "$bats_file" | sort >"$snap"

  run frozen_monolith_check "$bats_file" "$snap" "fixture-mark" "tests/fixture-<scope>.bats" "tests/fixture-monolith.bats"
  [ "$status" -eq 0 ]
  [[ "$output" == *"frozen (new scopes go in tests/fixture-<scope>.bats)"* ]]
}

@test "frozen_monolith_check() fails and points at the scope hint when the @test set drifts from the snapshot" {
  source "$REPO/scripts/lib/frozen-monolith-check.sh"

  local bats_file="$BATS_TEST_TMPDIR/fixture-monolith-drift.bats"
  local snap="$BATS_TEST_TMPDIR/.fixture-titles-drift"
  cat >"$bats_file" <<'EOF'
#!/usr/bin/env bats
AT_TEST "alpha does a thing" {
  true
}
AT_TEST "beta does another thing" {
  true
}
EOF
  sed -i 's/^AT_TEST /@test /' "$bats_file"
  grep -oE '^@test "[^"]*"' "$bats_file" | sort >"$snap"

  # Simulate a PR appending a new @test straight to the frozen monolith.
  cat >>"$bats_file" <<'EOF'
AT_TEST "gamma is a new test that should not have been appended here" {
  true
}
EOF
  sed -i 's/^AT_TEST /@test /' "$bats_file"

  run frozen_monolith_check "$bats_file" "$snap" "fixture-mark" "tests/fixture-<scope>.bats" "tests/fixture-monolith.bats"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
  [[ "$output" == *"Add NEW tests in tests/fixture-<scope>.bats"* ]]
  [[ "$output" == *"make fixture-mark"* ]]
}

@test "frozen_monolith_check() is a no-op when the target bats file doesn't exist" {
  source "$REPO/scripts/lib/frozen-monolith-check.sh"

  run frozen_monolith_check "$BATS_TEST_TMPDIR/does-not-exist.bats" "$BATS_TEST_TMPDIR/does-not-exist-snap" "fixture-mark" "tests/fixture-<scope>.bats" "tests/fixture-monolith.bats"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

# --- frozen_monolith_sync_hook() direct behavior -------------------------
# The hook function shells out to a caller-supplied check script (bash
# "$root/$check_script"), so these fixtures include a minimal check script
# that wraps frozen_monolith_check() around the same fixture files above.

setup_hook_fixtures() {
  ROOT="$BATS_TEST_TMPDIR/hookroot"
  mkdir -p "$ROOT/tests" "$ROOT/scripts"

  cat >"$ROOT/tests/fixture-monolith.bats" <<'EOF'
#!/usr/bin/env bats
AT_TEST "alpha does a thing" {
  true
}
EOF
  sed -i 's/^AT_TEST /@test /' "$ROOT/tests/fixture-monolith.bats"
  grep -oE '^@test "[^"]*"' "$ROOT/tests/fixture-monolith.bats" | sort >"$ROOT/tests/.fixture-titles"

  cat >"$ROOT/scripts/fixture-check.sh" <<EOF
#!/usr/bin/env bash
set -uo pipefail
source "$REPO/scripts/lib/frozen-monolith-check.sh"
frozen_monolith_check \
  "$ROOT/tests/fixture-monolith.bats" \
  "$ROOT/tests/.fixture-titles" \
  "fixture-mark" \
  "tests/fixture-<scope>.bats" \
  "tests/fixture-monolith.bats"
exit \$?
EOF
  chmod +x "$ROOT/scripts/fixture-check.sh"
}

# NOTE: the JSON payload contains literal double quotes, so it is passed to
# frozen_monolith_sync_hook via stdin redirection on a real shell variable
# (never re-embedded as literal text inside a nested `bash -c '...'` string)
# — textual re-embedding would let the payload's own `"` characters break out
# of the reconstructed command's quoting.

@test "frozen_monolith_sync_hook() does nothing (exit 0) for an edit to a file other than the monolith" {
  source "$REPO/scripts/lib/frozen-monolith-sync-hook.sh"
  setup_hook_fixtures

  payload='{"tool_input":{"file_path":"'"$ROOT"'/tests/some-other-file.bats"}}'
  run frozen_monolith_sync_hook "tests/fixture-monolith.bats" "scripts/fixture-check.sh" "fixture-mark" "tests/fixture-<scope>.bats" "$ROOT" <<< "$payload"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "frozen_monolith_sync_hook() exits 2 with FROZEN guidance when the edited file IS the drifted monolith" {
  source "$REPO/scripts/lib/frozen-monolith-sync-hook.sh"
  setup_hook_fixtures

  # Drift the monolith after the snapshot was taken, same as the check test above.
  cat >>"$ROOT/tests/fixture-monolith.bats" <<'EOF'
AT_TEST "gamma is a new test that should not have been appended here" {
  true
}
EOF
  sed -i 's/^AT_TEST /@test /' "$ROOT/tests/fixture-monolith.bats"

  payload='{"tool_input":{"file_path":"'"$ROOT"'/tests/fixture-monolith.bats"}}'
  run frozen_monolith_sync_hook "tests/fixture-monolith.bats" "scripts/fixture-check.sh" "fixture-mark" "tests/fixture-<scope>.bats" "$ROOT" <<< "$payload"
  [ "$status" -eq 2 ]
  [[ "$output" == *"FROZEN"* ]]
  [[ "$output" == *"tests/fixture-<scope>.bats"* ]]
}

@test "frozen_monolith_sync_hook() exits 0 for an edit to the monolith that matches its snapshot" {
  source "$REPO/scripts/lib/frozen-monolith-sync-hook.sh"
  setup_hook_fixtures

  payload='{"tool_input":{"file_path":"'"$ROOT"'/tests/fixture-monolith.bats"}}'
  run frozen_monolith_sync_hook "tests/fixture-monolith.bats" "scripts/fixture-check.sh" "fixture-mark" "tests/fixture-<scope>.bats" "$ROOT" <<< "$payload"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- recurrence guard -----------------------------------------------------
# The gap this item fixes: frozen-monolith-check.sh/-sync-hook.sh had zero
# direct tests/*.bats coverage despite three other scripts/lib/*.sh
# extractions each carrying their own <name>-lib.bats. Turn that observation
# into a permanent gate so a future fifth (or sixth) lib/*.sh extraction can't
# silently skip the direct-unit-test half of the pattern again.
@test "every scripts/lib/*.sh file is referenced by name in at least one tests/*.bats file" {
  cd "$REPO"
  missing=""
  for f in scripts/lib/*.sh; do
    base="$(basename "$f")"
    if ! grep -rl -- "$base" tests/*.bats >/dev/null 2>&1; then
      missing="$missing $base"
    fi
  done
  [ -z "$missing" ]
}
