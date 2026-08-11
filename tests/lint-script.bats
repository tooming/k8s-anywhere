#!/usr/bin/env bats
# Clusterless structural + behavioral tests for scripts/lint.sh — the gate that
# runs on every commit (`make lint`, the pre-push hook) and in CI's `lint` job.
# Like scripts/validate-kustomize.sh / validate-manifests.sh / validate-terraform.sh
# (tests/validate-scripts.bats), it had zero bats coverage of its own behavior
# despite being the single most-invoked quality gate in the repo — a dropped
# ${CI:-} check here would silently turn the CI lint job into an always-green
# no-op with nothing catching the regression.

# Build a PATH with shellcheck/yamllint hidden but every other command (bash,
# grep, coreutils, ...) still resolvable — package managers commonly install
# shellcheck/yamllint into the same directory as bash itself (e.g. apt →
# /usr/bin), so simply dropping that whole directory from PATH breaks the
# script's own shebang/builtins with an unrelated "command not found" (127)
# instead of exercising the "tool not installed" branch this is meant to test.
# Shadow only the two binaries: a shim dir goes first in PATH, symlinking every
# entry of each real PATH dir except shellcheck/yamllint. Built once for the
# whole file (setup_file, BATS_FILE_TMPDIR) — per-test would re-walk PATH 14x.
setup_file() {
  SHIM="$BATS_FILE_TMPDIR/shim-bin"
  mkdir -p "$SHIM"
  printf '%s' "$PATH" | tr ':' '\n' | while read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      base="$(basename "$f")"
      [ "$base" = "shellcheck" ] && continue
      [ "$base" = "yamllint" ] && continue
      [ -e "$SHIM/$base" ] && continue
      ln -s "$f" "$SHIM/$base" 2>/dev/null || true
    done
  done
}

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO/scripts/lint.sh"
  MAKEFILE="$REPO/Makefile"
  STRIPPED_PATH="$BATS_FILE_TMPDIR/shim-bin"
}

@test "lint.sh exists" {
  [ -f "$LINT" ]
}

@test "lint.sh is executable" {
  [ -x "$LINT" ]
}

@test "lint.sh skips both tools locally (exit 0) when neither is installed" {
  # -u CI: CI runners (including the one running this suite) set CI=true in the
  # ambient environment, which `env FOO=bar` alone does not clear.
  run env -u CI PATH="$STRIPPED_PATH" bash "$LINT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"shellcheck not installed"* ]]
  [[ "$output" == *"yamllint not installed"* ]]
}

@test "lint.sh FAILS (exit 1) in CI when shellcheck/yamllint are not installed" {
  run env -u CI PATH="$STRIPPED_PATH" CI=true bash "$LINT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"shellcheck not installed (required in CI)"* ]]
  [[ "$output" == *"yamllint not installed (required in CI)"* ]]
}

@test "lint.sh defaults SHELLCHECK_SEVERITY to warning" {
  run grep -q 'SHELLCHECK_SEVERITY="\${SHELLCHECK_SEVERITY:-warning}"' "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh SHELLCHECK_SEVERITY is overridable via env" {
  # A regression here (hardcoding "warning" instead of reading the env var)
  # would silently stop CI from ever tightening the severity gate.
  run env -u CI PATH="$STRIPPED_PATH" SHELLCHECK_SEVERITY=error bash "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh runs shellcheck over every scripts/*.sh file" {
  run grep -q 'shellcheck -S "\$SHELLCHECK_SEVERITY" scripts/\*\.sh' "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh runs yamllint with the repo's .yamllint.yml config" {
  run grep -q -- '-c \.yamllint\.yml' "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh only yamllints directories that actually exist (gitops/infra/.github/.forgejo)" {
  run grep -q 'for d in gitops infra \.github \.forgejo; do \[ -e "\$d" \] && targets+=("\$d"); done' "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh exits 0 on clean and 1 on findings" {
  run grep -q 'lint: PASS' "$LINT"
  [ "$status" -eq 0 ]
  run grep -q 'lint: FAIL' "$LINT"
  [ "$status" -eq 0 ]
  run grep -q 'exit "\$drift"' "$LINT"
  [ "$status" -eq 0 ]
}

@test "lint.sh actually passes against this repo's own scripts + manifests" {
  # Real end-to-end run (not the tool-missing branch) against the repo checked
  # out for this test suite — catches an actual shellcheck/yamllint regression,
  # not just the gate's plumbing. Skips cleanly if the tools aren't on PATH.
  if ! command -v shellcheck >/dev/null 2>&1 || ! command -v yamllint >/dev/null 2>&1; then
    skip "shellcheck and/or yamllint not installed in this test environment"
  fi
  run bash "$LINT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lint: PASS"* ]]
}

# --- Makefile + pre-push hook wiring ------------------------------------------
@test "Makefile lint target invokes lint.sh" {
  run grep -A1 '^lint:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lint.sh"* ]]
}

@test "Makefile ci target invokes lint.sh first" {
  run grep -A2 '^ci:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lint.sh"* ]]
}

@test ".githooks/pre-push runs the lint gate (fast path, not full make ci)" {
  run grep -q 'make -C "\$ROOT" lint' "$REPO/.githooks/pre-push"
  [ "$status" -eq 0 ]
}
