#!/usr/bin/env bats
# Structural coverage for docs/dependency-register.md (ROADMAP "Third-party
# dependency register" item, DORA audit readiness Q14). Clusterless — every
# assertion is a grep against real, committed doc content.

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DOC="$REPO/docs/dependency-register.md"
  AUDIT="$REPO/docs/dora-audit-readiness.md"
  ARCHITECT_PROMPT="$REPO/routines/architect.prompt.md"
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

@test "Garage's upstream org slug is deuxfleurs-org, not the dead Deuxfleurs/deuxfleurs (ADR-0002 2026-08-19)" {
  # github.com/Deuxfleurs/garage (and github.com/deuxfleurs/garage, missing the
  # -org suffix) both 404 — the real org is deuxfleurs-org. This bug was
  # invisible to markdown-links-check (bare external URLs, not [text](path)
  # links) and silently broke the architect routine's own weekly upstream
  # release check for Garage. Pin the correct slug in both files that name it.
  run grep -qF 'github.com/deuxfleurs-org/garage' "$DOC"
  [ "$status" -eq 0 ]
  run grep -qiE 'github\.com/deuxfleurs/garage|github\.com/Deuxfleurs/garage' "$DOC"
  [ "$status" -ne 0 ]

  run grep -qF 'deuxfleurs-org/garage' "$ARCHITECT_PROMPT"
  [ "$status" -eq 0 ]
  run grep -qiE '\bdeuxfleurs/garage\b' "$ARCHITECT_PROMPT"
  [ "$status" -ne 0 ]
}

@test "k3s row cites ADR-0030's Re-evaluation log for its real last-reviewed date, not 'not dated in ADR' (2026-08-24)" {
  # k3s's row correctly keeps ADR-0027 in the ADR column (the register's own
  # Scope note deliberately excludes ADR-0030 — a policy ADR "enforced via
  # k3s, whose backend choice ADR-0027 already covers"), but ADR-0030 is
  # where k3s's actual version-currency re-evaluation history lives (audited
  # 2026-08-05, 2026-07-28, 2026-08-20). Citing only ADR-0027's authoring
  # date ("not dated in ADR") understated real, tracked currency review —
  # same class of bug this file's own history already corrected for three
  # other rows (docs/done/2026-08-12-dependency-register-log-drift-fix.md)
  # and the PR #1283 Loki/Tempo ADR-0034-authoring-date fix.
  k3s_line=$(grep -E '^\| k3s \|' "$DOC")
  [ -n "$k3s_line" ]
  grep -q 'adr-0030-pin-k3s-version-explicitly.md' <<<"$k3s_line"
  ! grep -q 'not dated in ADR' <<<"$k3s_line"
}

@test "dora-audit-readiness.md's Q14 answer is no longer 'Not as a single consolidated register'" {
  q14_block=$(awk '/\*\*Q14\./{flag=1} flag{print} /\*\*Q15\./{exit}' "$AUDIT")
  [ -n "$q14_block" ]
  ! grep -q 'Not as a single consolidated register' <<<"$q14_block"
  grep -q 'dependency-register.md' <<<"$q14_block"
}
