#!/usr/bin/env bats
# Recurrence guard for docs/00-architecture.md's embedded dashboard-count
# claim going stale — found live 2026-08-20: the doc claimed "36 dashboard
# files total... 29 lab dashboards" while grafana/dashboards/*.json actually
# held 39 files (32 always-on lab dashboards after excluding the 7 tied to
# on-demand/heavy components), with no mechanical check catching the drift.
# CLAUDE.md's "every bugfix must prevent recurrence" rule: this asserts the
# doc's own claimed numbers against the real directory, so the next
# dashboard added without updating this line fails make ci instead of
# silently going stale again.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DOC="$REPO/docs/00-architecture.md"
  DASHBOARD_DIR="$REPO/grafana/dashboards"
}

@test "docs/00-architecture.md's Grafana row cites the real total dashboard-file count" {
  [ -f "$DOC" ]
  real_total="$(find "$DASHBOARD_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
  run grep -oE '[0-9]+ dashboard files total' "$DOC"
  [ "$status" -eq 0 ]
  claimed_total="$(echo "$output" | grep -oE '^[0-9]+')"
  [ "$claimed_total" -eq "$real_total" ]
}

@test "docs/00-architecture.md's Grafana row cites the real always-on lab-dashboard count (total minus the 7 on-demand-tied dashboards)" {
  [ -f "$DOC" ]
  real_total="$(find "$DASHBOARD_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
  # The 7 on-demand/heavy-tied dashboards the doc's own prose names explicitly.
  ondemand_count=7
  real_always_on=$((real_total - ondemand_count))
  run grep -oE '[0-9]+ lab dashboards' "$DOC"
  [ "$status" -eq 0 ]
  claimed_always_on="$(echo "$output" | grep -oE '^[0-9]+')"
  [ "$claimed_always_on" -eq "$real_always_on" ]
}
