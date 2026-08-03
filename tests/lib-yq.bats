#!/usr/bin/env bats
# Clusterless behavioral tests for scripts/lib/yq.sh's yqs() — the shared
# yq-variant-robust scalar-read helper for scripts/*.sh (mirrors
# tests/lib/yq.bash's yqs() for bats tests). Extracted from two
# byte-identical copies that used to live inline in
# scripts/adr-chart-version-sync-check.sh and
# scripts/context-doc-version-sync-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LIB="$REPO/scripts/lib/yq.sh"
  source "$LIB"
}

@test "scripts/lib/yq.sh exists" {
  [ -f "$LIB" ]
}

@test "yq.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$LIB"
  [ "$status" -eq 0 ]
}

@test "yq.sh defines yqs()" {
  run grep -q '^yqs()' "$LIB"
  [ "$status" -eq 0 ]
}

@test "yqs: strips surrounding double quotes from yq output" {
  yq() { printf '"250m"'; }
  run yqs '.foo' file.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "250m" ]
}

@test "yqs: passes through unquoted yq output unchanged" {
  yq() { printf '250m'; }
  run yqs '.foo' file.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "250m" ]
}

@test "yqs: propagates yq's non-zero exit code" {
  yq() { return 4; }
  run yqs '.foo' file.yaml
  [ "$status" -eq 4 ]
  [ -z "$output" ]
}

@test "yqs: swallows yq's stderr on failure (2>/dev/null)" {
  yq() { echo "some yq parse error" >&2; return 1; }
  run yqs '.foo' file.yaml
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
