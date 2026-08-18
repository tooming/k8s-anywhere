#!/usr/bin/env bats
# Clusterless structural tests for docs/dora-audit-readiness.md's "Stateless
# component criticality tiers" section (ROADMAP "Stateless-surface criticality
# tiering — closes DORA audit Q2's named gap"). New file per this repo's
# per-topic bats convention — do not append to an unrelated monolith.
#
# Distinct from tests/dora-metrics.bats, which covers CHARTER O7's separate
# `make dora-metrics` delivery-metrics feature, not this audit doc.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DOC="$REPO/docs/dora-audit-readiness.md"
}

@test "dora-audit-readiness.md has the Stateless component criticality tiers section" {
  run grep -q '^### Stateless component criticality tiers$' "$DOC"
  [ "$status" -eq 0 ]
}

@test "criticality tiering names Cilium at P0 (recurrence guard: highest-severity row can't silently drop)" {
  run grep -q '| Cilium | \*\*P0\*\*' "$DOC"
  [ "$status" -eq 0 ]
}

@test "criticality tiering names Envoy Gateway at P0 (recurrence guard: highest-severity row can't silently drop)" {
  run grep -q '| Envoy Gateway | \*\*P0\*\*' "$DOC"
  [ "$status" -eq 0 ]
}

@test "criticality tiering reuses the existing incident-log.md P0-P3 scheme, not a new taxonomy" {
  run grep -q 'reused rather than inventing a second taxonomy' "$DOC"
  [ "$status" -eq 0 ]
}

@test "Q2's Gap line points at the new section instead of stating the gap as open" {
  run grep -qA1 '^\*\*Q2\.' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'Gap:\*\* closed below' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'no equivalent criticality tiering for the \*stateless\* surface' "$DOC"
  [ "$status" -ne 0 ]
}

@test "dependency-concentration.md exists (Q16 concentration-risk rollup)" {
  [ -f "$REPO/docs/dependency-concentration.md" ]
}

@test "dependency-concentration.md names github.com/grafana as the largest concentration (6 tools)" {
  CONC="$REPO/docs/dependency-concentration.md"
  run grep -q 'github.com/grafana` — 6 tools' "$CONC"
  [ "$status" -eq 0 ]
}

@test "Q16's Gap line points at the new file instead of stating the gap as open" {
  run grep -q 'docs/dependency-concentration.md' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'never rolled up into a single' "$DOC"
  [ "$status" -ne 0 ]
}

@test "dependency-exit-runbooks.md exists (Q17 exit-strategy runbooks)" {
  [ -f "$REPO/docs/dependency-exit-runbooks.md" ]
}

@test "dependency-exit-runbooks.md names all three concentration groups" {
  RUNBOOKS="$REPO/docs/dependency-exit-runbooks.md"
  run grep -q 'github.com/grafana' "$RUNBOOKS"
  [ "$status" -eq 0 ]
  run grep -q 'github.com/argoproj' "$RUNBOOKS"
  [ "$status" -eq 0 ]
  run grep -q 'github.com/pingcap' "$RUNBOOKS"
  [ "$status" -eq 0 ]
}

@test "Q17's Gap line points at the new file instead of stating the gap as purely reactive" {
  run grep -q 'docs/dependency-exit-runbooks.md' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'exits happen reactively (via a new ADR) rather than being' "$DOC"
  [ "$status" -ne 0 ]
}
