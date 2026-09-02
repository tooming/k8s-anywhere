#!/usr/bin/env bats
# Clusterless structural + functional tests for scripts/lib/dependency-register.sh
# — the shared docs/dependency-register.md table parser extracted 2026-09-02 when
# dependency-concentration-sync-check.sh needed the exact same row-enumeration
# logic dependency-maintenance-check.sh already had (janitor-style de-duplication,
# mirrors the earlier scripts/lib/colors.sh / scripts/lib/budget-check.sh
# extractions). Guards against the duplicate pattern creeping back in.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$REPO/scripts/lib/dependency-register.sh"
}

@test "scripts/lib/dependency-register.sh exists" {
  [ -f "$REPO/scripts/lib/dependency-register.sh" ]
}

@test "dependency-register.sh defines depreg_rows() and depreg_github_match()" {
  run grep -q "^depreg_rows()" "$REPO/scripts/lib/dependency-register.sh"
  [ "$status" -eq 0 ]
  run grep -q "^depreg_github_match()" "$REPO/scripts/lib/dependency-register.sh"
  [ "$status" -eq 0 ]
}

@test "dependency-register.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/dependency-register.sh"
  [ "$status" -eq 0 ]
}

@test "depreg_rows(): parses tool+source rows, skips the header row" {
  FIX="$BATS_TEST_TMPDIR/register.md"
  cat > "$FIX" << 'EOF'
# Register (fixture)

| Tool | Criticality | Upstream source | ADR | Last reviewed |
|---|---|---|---|---|
| Tool A | always-on-core | github.com/some-org/tool-a | ADR-0001 | 2026-08-01 |
| Tool B | always-on-core | cloud.example.com | ADR-0002 | 2026-08-01 |
EOF
  run depreg_rows "$FIX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Tool A"*"github.com/some-org/tool-a"* ]]
  [[ "$output" == *"Tool B"*"cloud.example.com"* ]]
  [[ "$output" != *$'\n'"Tool"$'\t'"Upstream source"* ]]
}

@test "depreg_github_match(): extracts owner/repo from a github.com source cell" {
  run depreg_github_match "grafana.com, github.com/grafana/grafana"
  [ "$status" -eq 0 ]
  [ "$output" = "grafana/grafana" ]
}

@test "depreg_github_match(): prints nothing for a non-github.com source cell" {
  run depreg_github_match "cloud.oracle.com"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "both dependency-maintenance-check.sh and dependency-concentration-sync-check.sh source this shared lib (no re-inlined copy)" {
  run grep -q 'lib/dependency-register.sh' "$REPO/scripts/dependency-maintenance-check.sh"
  [ "$status" -eq 0 ]
  run grep -q 'lib/dependency-register.sh' "$REPO/scripts/dependency-concentration-sync-check.sh"
  [ "$status" -eq 0 ]
}
