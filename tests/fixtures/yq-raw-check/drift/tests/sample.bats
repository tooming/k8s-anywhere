#!/usr/bin/env bats
# Drift fixture: a bare yq call the check must flag.
@test "reads a scalar via bare yq" {
  [ "$(yq '.a' "$BATS_TEST_DIRNAME/v.yaml")" = "x" ]
}
