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

@test "dependency-register.md has at least 5 data rows" {
  # Count markdown table rows starting with '| [' or '| ' that are real data
  # rows (exclude the header and the '|---|---|...' separator). Lowered from 20
  # to 10 2026-09-07 (Kyverno/Argo Rollouts/Velero/Trivy Operator/Kargo/moto/
  # ACK/KRO removed, 21->13 rows), then from 10 to 5 the same day when Vault
  # and External Secrets Operator were also removed entirely, no replacement
  # (ADR-0042), dropping the real row count to 7 (docs/dependency-register.md's
  # own Scope note) — a smaller register is the correct, honest reflection of a
  # smaller lab, not a regression to guard against.
  count=$(grep -cE '^\| [A-Za-z0-9]' "$DOC")
  [ "$count" -ge 5 ]
}

@test "dependency-register.md no longer has a Garage row (removed 2026-09-07, no replacement)" {
  # Garage (in-cluster S3, ADR-0002, and the off-cluster Terraform-state backend,
  # ADR-0007) was removed entirely 2026-09-07 alongside s3manager (its browser UI,
  # ADR-0039, orphaned the same day) — no live component left to cite a row for.
  run grep -q '^| Garage ' "$DOC"
  [ "$status" -ne 0 ]
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

@test "Garage's dead org slug never resurfaces, and the architect routine no longer tracks it as a release-check target (removed 2026-09-07, no replacement)" {
  # This test used to guard the correct deuxfleurs-org (not the dead Deuxfleurs/
  # deuxfleurs) org slug wherever Garage was named, after that exact typo once
  # silently broke the architect routine's own weekly upstream release check
  # (ADR-0002, found 2026-08-19). Garage itself was removed entirely 2026-09-07,
  # no replacement — the register's Scope note still names it in passing (why
  # ADR-0002/ADR-0007 contribute no row, same as every other removed component),
  # but there's no live component left to track a release-check slug for, so the
  # architect routine's per-release-check list should no longer name it at all,
  # and the dead slug (with or without -org) must never come back anywhere.
  run grep -qiE 'github\.com/deuxfleurs/garage|github\.com/Deuxfleurs/garage' "$DOC"
  [ "$status" -ne 0 ]
  # The architect prompt's removed-components list legitimately still names
  # Garage by name (why it's no longer tracked) — check it's not listed as an
  # active per-release-check target (that shape, "Garage: `slug`", not a bare
  # mention) instead of checking the word is absent entirely.
  run grep -qE '^\s*-\s*Garage:' "$ARCHITECT_PROMPT"
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
