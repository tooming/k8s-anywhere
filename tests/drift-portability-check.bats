#!/usr/bin/env bats
# Tests for scripts/portability-check.sh — the guard that keeps GNU-only shell
# idioms (grep -P, bare `sed -i`, `timeout`, `realpath -m`, `date -d`, …) out of
# scripts/, tests/, .githooks/ and the Makefile, because a stock macOS rejects
# them and `make ci` is run there too (#1637). Trees are built on the fly under
# $BATS_TEST_TMPDIR, so this file needs no committed fixtures. This file quotes the
# idioms, so the check exempts it by name (see the script's header).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/portability-check.sh"
  T="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$T/scripts" "$T/tests/fixtures" "$T/.githooks"
}

# scan <relative path> <line> : write a one-line file and run the check on it
scan() {
  mkdir -p "$(dirname "$T/$1")"
  printf '%s\n' "$2" >"$T/$1"
  run env PORTABILITY_ROOT="$T" bash "$SCRIPT"
}

@test "portability-check: passes on a tree using only portable forms" {
  cat >"$T/scripts/ok.sh" <<'SH'
#!/usr/bin/env bash
grep -E 'a|b' file
sed 's/a/b/' file >tmp && mv tmp file
sed -i.bak 's/a/b/' file
run_with_timeout 30 curl -fsS x
gtimeout 30 true
command -v timeout >/dev/null
realpath file
date -u +%s
stat -f %z file
readlink -f file
sed -r 's/a+/b/' file
find . -name '*.md' -print0
head -n 5 file
SH
  run env PORTABILITY_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no GNU-only idioms"* ]]
}

@test "portability-check: flags every GNU-only idiom, naming file:line and the fix" {
  local rule line
  while IFS='|' read -r rule line; do
    scan scripts/bad.sh "$line"
    [ "$status" -eq 1 ] || { echo "NOT flagged ($rule): $line"; return 1; }
    [[ "$output" == *"scripts/bad.sh:1: $rule"* ]] || { echo "wrong rule for: $line -> $output"; return 1; }
  done <<'RULES'
grep -P|grep -P 'a\Kb' file
grep -P|grep -oP '\]\(\K[^)]+' file
grep -P|awk 1 f | grep -n -P x
grep -P|egrep --perl-regexp x file
sed -i without an attached suffix|sed -i 's/a/b/' file
sed -i without an attached suffix|  sed -Ei 's/a/b/' file
sed -i without an attached suffix|sed -i '' 's/a/b/' file
sed -i without an attached suffix|sed -n -i 's/a/b/p' file
sed -i without an attached suffix|sed --in-place 's/a/b/' file
bare timeout|run env -i PATH=x timeout 30 bash hook
bare timeout|if ! timeout 20 curl -fsS x; then
bare timeout|x=$(timeout -k 5 30 cmd)
realpath with options|target="$(realpath -m --relative-to="$ROOT" "$p")"
realpath with options|realpath --relative-to=. x
date -d|date -u -d "$ts" +%s
date -d|date -d @123 +%F
stat -c|stat -c %s file
stat -c|size=$(stat -c '%s' f)
find -printf / -regextype|find . -name x -printf '%p\n'
find -printf / -regextype|find . -regextype posix-extended -name x
head -n -N|head -n -1 file
tac|tac file
tac|cat f | tac
mktemp --suffix|mktemp --suffix=.yaml
RULES
}

@test "portability-check: an inline portability-ok marker exempts that one line, and only that line" {
  printf '%s\n%s\n' \
    "date -u -d \"\$x\" +%s || date -u -jf f \"\$x\" +%s  # portability-ok: BSD fallback" \
    "date -u -d \"\$y\" +%s" >"$T/scripts/mix.sh"
  run env PORTABILITY_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"scripts/mix.sh:2:"* ]]
  [[ "$output" != *"scripts/mix.sh:1:"* ]]
}

@test "portability-check: comment-only lines and prose that merely mentions a tool are not flagged" {
  cat >"$T/scripts/c.sh" <<'SH'
# grep -P is GNU-only; sed -i needs a suffix on BSD; timeout 30 is missing on macOS
    # realpath -m and date -d are unavailable too
echo "run_with_timeout 30 wraps timeout"
SH
  run env PORTABILITY_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "portability-check: scans scripts, tests, .githooks and the Makefile — but not tests/fixtures" {
  scan scripts/lib/deep.sh 'x=$(timeout 5 cmd)'
  [ "$status" -eq 1 ]; [[ "$output" == *"scripts/lib/deep.sh:1:"* ]]
  rm -f "$T/scripts/lib/deep.sh"
  scan tests/some.bats "  sed -i 's/a/b/' f"
  [ "$status" -eq 1 ]; [[ "$output" == *"tests/some.bats:1:"* ]]
  rm -f "$T/tests/some.bats"
  scan tests/lib/helper.bash "grep -P x f"
  [ "$status" -eq 1 ]; [[ "$output" == *"tests/lib/helper.bash:1:"* ]]
  rm -f "$T/tests/lib/helper.bash"
  scan .githooks/pre-push 'tac f'
  [ "$status" -eq 1 ]; [[ "$output" == *".githooks/pre-push:1:"* ]]
  rm -f "$T/.githooks/pre-push"
  scan Makefile $'\t@stat -c %s f'
  [ "$status" -eq 1 ]; [[ "$output" == *"Makefile:1:"* ]]
  rm -f "$T/Makefile"
  # deliberate bad examples live under tests/fixtures and must be ignored
  scan tests/fixtures/x/bad.sh "sed -i 's/a/b/' f"
  [ "$status" -eq 0 ]
}

@test "portability-check: the check's own files, which quote the idioms, are exempt" {
  scan scripts/portability-check.sh "grep -P x f"
  [ "$status" -eq 0 ]
  scan tests/drift-portability-check.bats "sed -i 's/a/b/' f"
  [ "$status" -eq 0 ]
}

@test "portability-check: FAILS LOUDLY when grep itself errors (never reports clean without checking)" {
  mkdir -p "$BATS_TEST_TMPDIR/badgrep"
  printf '#!/bin/sh\necho "grep: simulated failure" >&2\nexit 2\n' >"$BATS_TEST_TMPDIR/badgrep/grep"
  chmod +x "$BATS_TEST_TMPDIR/badgrep/grep"
  echo 'echo ok' >"$T/scripts/a.sh"
  run env PATH="$BATS_TEST_TMPDIR/badgrep:$PATH" PORTABILITY_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"did not run"* ]]
  [[ "$output" != *"no GNU-only idioms"* ]]
}

@test "portability-check: a root with nothing to scan is a clean no-op" {
  run env PORTABILITY_ROOT="$BATS_TEST_TMPDIR" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]]
}

@test "portability-check: passes on the real repo" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}
