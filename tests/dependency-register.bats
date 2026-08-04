#!/usr/bin/env bats
# Structural coverage for docs/dependency-register.md (ROADMAP "Third-party
# dependency register" item, DORA audit readiness Q14). Clusterless — every
# assertion is a grep against real, committed doc content.

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DOC="$REPO/docs/dependency-register.md"
  AUDIT="$REPO/docs/dora-audit-readiness.md"
}

@test "docs/dependency-register.md exists" {
  [ -f "$DOC" ]
}

@test "dependency-register.md has the five-column header row" {
  run grep -q '| Tool | Criticality | Upstream source | ADR | Last reviewed |' "$DOC"
  [ "$status" -eq 0 ]
}

@test "dependency-register.md has at least 20 data rows" {
  # Count markdown table rows starting with '| [' or '| ' that are real data
  # rows (exclude the header and the '|---|---|...' separator).
  count=$(grep -cE '^\| [A-Za-z0-9]' "$DOC")
  [ "$count" -ge 20 ]
}

@test "dependency-register.md includes a Garage row citing ADR-0002" {
  run grep -q 'Garage' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'adr-0002-garage-not-minio.md' "$DOC"
  [ "$status" -eq 0 ]
}

@test "dependency-register.md includes a Valkey row citing ADR-0018" {
  run grep -q 'Valkey' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'adr-0018-valkey-not-redis.md' "$DOC"
  [ "$status" -eq 0 ]
}

@test "dependency-register.md explains its relationship to dependency-tree.md and decisions/" {
  run grep -q 'dependency-tree.md' "$DOC"
  [ "$status" -eq 0 ]
  run grep -qi 'decisions/' "$DOC"
  [ "$status" -eq 0 ]
}

@test "dependency-register.md documents its own scope exclusions" {
  run grep -qi 'Superseded' "$DOC"
  [ "$status" -eq 0 ]
  run grep -qi 'not a third-party dependency\|Scope note' "$DOC"
  [ "$status" -eq 0 ]
}

@test "dependency-register.md has no fabricated/placeholder content (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy)"' "$DOC"
  [ "$status" -ne 0 ]
}

@test "dora-audit-readiness.md's Q14 answer is no longer 'Not as a single consolidated register'" {
  q14_block=$(awk '/\*\*Q14\./{flag=1} flag{print} /\*\*Q15\./{exit}' "$AUDIT")
  [ -n "$q14_block" ]
  ! grep -q 'Not as a single consolidated register' <<<"$q14_block"
  grep -q 'dependency-register.md' <<<"$q14_block"
}
