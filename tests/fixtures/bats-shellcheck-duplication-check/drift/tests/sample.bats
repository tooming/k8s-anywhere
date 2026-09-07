#!/usr/bin/env bats
# Drift fixture: a bats test that invokes shellcheck directly on a single
# script. The check must flag this — it's redundant with make lint's own
# repo-wide shellcheck coverage, and lacks that gate's skip-when-uninstalled
# guard.
setup() {
  SCRIPT="$(mktemp)"
}
teardown() { rm -f "$SCRIPT"; }

@test "sample.sh passes shellcheck" {
  run shellcheck --severity=warning "$SCRIPT"
  [ "$status" -eq 0 ]
}
