#!/usr/bin/env bats
# Clusterless structural tests for scripts/lib/colors.sh — the shared ANSI
# color-setup snippet extracted from 15 near-identical inline copies across
# scripts/*.sh (janitor cleanup). Guards against the duplicate pattern
# creeping back in as new scripts get added.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "scripts/lib/colors.sh exists" {
  [ -f "$REPO/scripts/lib/colors.sh" ]
}

@test "colors.sh defines all five color variables in both tty branches" {
  for v in G R Y B Z; do
    run grep -q "$v=" "$REPO/scripts/lib/colors.sh"
    [ "$status" -eq 0 ]
  done
}

@test "colors.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/colors.sh"
  [ "$status" -eq 0 ]
}

# --- recurrence guard: no script re-inlines the duplicated pattern -----------
# Every scripts/*.sh that prints colored output must source lib/colors.sh
# rather than re-declaring "if [ -t 1 ]; then G=...". Only colors.sh itself
# (and this guard's own fixture-free check) should ever contain that literal
# pattern.
@test "no script under scripts/ re-inlines the color-setup pattern (source lib/colors.sh instead)" {
  run grep -rl "^if \[ -t 1 \]; then G=" "$REPO/scripts"
  [ "$status" -ne 0 ]
}

# Broader guard than the check above (found in a 2026-07-19 janitor sweep): the
# single-line "^if [ -t 1 ]; then G=" grep only catches one exact shape. It
# missed a multi-line "if [ -t 1 ]; then" / "G=..." split across two lines, a
# same-line block starting with a different variable ("R=" instead of "G="),
# and bare unconditional "\033[31m"-style literals with no tty check at all.
# Rather than chase each new shape with its own regex, assert the invariant
# directly: any script defining a raw \033 escape code must source
# lib/colors.sh (the two are the same class of drift regardless of shape).
@test "no script under scripts/ defines raw \\033 escape codes without sourcing lib/colors.sh" {
  hits=""
  for f in "$REPO"/scripts/*.sh; do
    grep -q '\\033\[' "$f" || continue
    grep -q 'lib/colors\.sh' "$f" || hits="$hits $f"
  done
  [ -z "$hits" ]
}

@test "every script sourcing lib/colors.sh does so via BASH_SOURCE-relative path" {
  run grep -rl 'source "\$(dirname "\${BASH_SOURCE\[0\]}")/lib/colors.sh"' "$REPO/scripts"
  [ "$status" -eq 0 ]
  # Spot-check a sample: at least 10 scripts adopted the shared lib.
  count="$(grep -rl 'source "\$(dirname "\${BASH_SOURCE\[0\]}")/lib/colors.sh"' "$REPO/scripts" | wc -l)"
  [ "$count" -ge 10 ]
}
