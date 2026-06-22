#!/usr/bin/env bats
# Golden fixture: reads yq scalars through yqs() — no bare yq. Mentioning yq in a
# comment must NOT trip the check.
load lib/yq

@test "reads a scalar via yqs" {
  [ "$(yqs '.a' "$BATS_TEST_DIRNAME/v.yaml")" = "x" ]
}
