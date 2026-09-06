#!/usr/bin/env bats
# Recurrence guard for docs/00-architecture.md's embedded dashboard-count claim.
# This file used to assert the doc's "N dashboard files total... M lab dashboards"
# claim against the real grafana/dashboards/ directory (found live 2026-08-20: the
# doc had gone stale against the real file count, with no mechanical check catching
# the drift). The observability stack — Grafana included — was removed entirely
# 2026-09-06 with no replacement (ADR-0041, supersedes ADR-0006/ADR-0034): there is
# no grafana/ directory and no dashboard-count claim left to keep in sync. This file
# now guards the opposite regression — that no stale dashboard-count claim or
# observability-stack reference creeps back into the doc.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DOC="$REPO/docs/00-architecture.md"
}

@test "docs/00-architecture.md exists" {
  [ -f "$DOC" ]
}

@test "grafana/ directory no longer exists (ADR-0041)" {
  [ ! -d "$REPO/grafana" ]
}

@test "docs/00-architecture.md no longer claims a dashboard-file count" {
  run grep -qE '[0-9]+ dashboard files total' "$DOC"
  [ "$status" -ne 0 ]
}

@test "docs/00-architecture.md no longer claims a lab-dashboard count" {
  run grep -qE '[0-9]+ lab dashboards' "$DOC"
  [ "$status" -ne 0 ]
}

@test "docs/00-architecture.md records the observability stack's removal (ADR-0041)" {
  run grep -q 'ADR-0041' "$DOC"
  [ "$status" -eq 0 ]
}

@test "docs/00-architecture.md no longer has an Observability (LGTMP) table section" {
  run grep -q '### Observability (LGTMP)' "$DOC"
  [ "$status" -ne 0 ]
}
