#!/usr/bin/env bats
# Tests for scripts/lib/timeout.sh (run_with_timeout) — the portable stand-in for
# GNU `timeout`, which a stock macOS lacks (#1637). Each dispatch branch
# (timeout, gtimeout, perl alarm) is forced hermetically by running under
# `env -i PATH=<dir of symlinks/stubs>`, so the result does not depend on what the
# machine running the suite happens to have installed.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LIB="$REPO/scripts/lib/timeout.sh"
  BIN="$(mktemp -d)"
  # Absolute: under `env -i PATH="$BIN"` a bare `bash` would not resolve, and every
  # in_env call would exit 127 -- silently passing any "status -ne 0" assertion.
  BASH_BIN="$(command -v bash)"
}

teardown() {
  rm -rf "$BIN"
}

# link_tools <name>... : symlink real binaries into $BIN (fails the test if missing)
link_tools() {
  local t
  for t in "$@"; do
    [ -n "$(command -v "$t")" ] || skip "$t not installed in this test environment"
    ln -s "$(command -v "$t")" "$BIN/$t"
  done
}

# stub <name> : a command that just reports how it was called
stub() {
  printf '#!/bin/sh\necho "%s $*"\n' "$1" >"$BIN/$1"
  chmod +x "$BIN/$1"
}

# in_env <cmd...> : source the lib and run cmd under a PATH of only $BIN
in_env() {
  env -i PATH="$BIN" "$BASH_BIN" -c 'source "$1"; shift; run_with_timeout "$@"' _ "$LIB" "$@"
}

@test "timeout.sh exists and defines run_with_timeout" {
  [ -f "$LIB" ]
  run bash -c 'source "$1"; type -t run_with_timeout' _ "$LIB"
  [ "$status" -eq 0 ]
  [ "$output" = "function" ]
}

@test "run_with_timeout: prefers timeout when present" {
  stub timeout
  stub gtimeout
  run in_env 7 echo hi
  [ "$status" -eq 0 ]
  [ "$output" = "timeout 7 echo hi" ]
}

@test "run_with_timeout: falls back to gtimeout (Homebrew coreutils) when timeout is absent" {
  stub gtimeout
  run in_env 7 echo hi
  [ "$status" -eq 0 ]
  [ "$output" = "gtimeout 7 echo hi" ]
}

@test "run_with_timeout: perl fallback passes the command's output and exit status through" {
  link_tools perl
  run in_env 5 "$BASH_BIN" -c 'echo out; exit 7'
  [ "$status" -eq 7 ]
  [ "$output" = "out" ]
}

@test "run_with_timeout: perl fallback kills a command that outlives the limit" {
  link_tools perl sleep
  local start=$SECONDS
  run in_env 1 sleep 30
  # 142 = 128 + SIGALRM. Explicitly not 127: that would mean `sleep` never ran.
  [ "$status" -eq 142 ]
  [ $((SECONDS - start)) -lt 10 ]
}

@test "run_with_timeout: perl fallback reports 127 for a command that does not exist" {
  link_tools perl
  local rc=0
  in_env 5 definitely-not-a-command-xyz || rc=$?
  [ "$rc" -eq 127 ]
}

@test "run_with_timeout: whichever implementation this machine has, a slow command is cut off" {
  local start=$SECONDS
  run bash -c 'source "$1"; run_with_timeout 1 sleep 30' _ "$LIB"
  [ "$status" -ne 0 ]
  [ $((SECONDS - start)) -lt 10 ]
}
