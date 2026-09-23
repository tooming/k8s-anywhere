#!/usr/bin/env bats
# Portability + fail-loud coverage for scripts/markdown-links-check.sh (#1637).
# The script used `grep -P` and `realpath -m --relative-to`, neither of which a
# stock macOS has; the grep error was swallowed inside a `< <(...)` process
# substitution, so the gate printed "every internal markdown link resolves" while
# checking nothing. Own file per the frozen-drift-detectors.bats rule; the basic
# in-sync / broken-link cases stay in tests/drift-detectors.bats.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/markdown-links-check.sh"
  T="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$T/docs/sub" "$T/other"
  touch "$T/README.md" "$T/other/ok.md" "$T/docs/ok2.md"
}

@test "markdown-links-check: resolves ../ climbing, root-absolute, directory and anchor links" {
  cat >"$T/docs/sub/x.md" <<'MD'
[a](../../other/ok.md)
[b](/README.md)
[c](../sub/)
[d](../ok2.md#section)
[e](https://example.com/none)
[f](#local-anchor)
MD
  run env MDLINKS_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "markdown-links-check: flags a missing target with its normalized path, and a link escaping the root" {
  cat >"$T/docs/sub/x.md" <<'MD'
[ok](../ok2.md)
[gone](../nope.md#x)
[sibling](./ok3.md)
[escape](../../../../escape.md)
MD
  run env MDLINKS_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"[../nope.md#x] -> docs/nope.md"* ]]
  [[ "$output" == *"[./ok3.md] -> docs/sub/ok3.md"* ]]
  [[ "$output" == *"[../../../../escape.md] -> ../../escape.md"* ]]
  [[ "$output" != *"[../ok2.md]"* ]]
}

@test "markdown-links-check: links inside fenced blocks and inline code spans are not checked" {
  printf 'text `[span](nope1.md)`\n```\n[fenced](nope2.md)\n```\n[real](../ok2.md)\n' >"$T/docs/sub/x.md"
  run env MDLINKS_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "markdown-links-check: a markdown file with no links at all is clean (grep 'no match' is not an error)" {
  printf 'just prose, no links\n' >"$T/docs/sub/x.md"
  run env MDLINKS_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every internal markdown link resolves"* ]]
}

@test "markdown-links-check: FAILS LOUDLY (never a false green) when link extraction itself errors" {
  # A grep that dies with a real error (status 2), as BSD grep did on `-P`.
  mkdir -p "$BATS_TEST_TMPDIR/badgrep"
  printf '#!/bin/sh\necho "grep: simulated extraction failure" >&2\nexit 2\n' >"$BATS_TEST_TMPDIR/badgrep/grep"
  chmod +x "$BATS_TEST_TMPDIR/badgrep/grep"
  printf '[a](../ok2.md)\n' >"$T/docs/sub/x.md"
  run env PATH="$BATS_TEST_TMPDIR/badgrep:$PATH" MDLINKS_ROOT="$T" bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"link extraction failed"* ]]
  [[ "$output" == *"NOT checked"* ]]
  [[ "$output" != *"every internal markdown link resolves"* ]]
}
