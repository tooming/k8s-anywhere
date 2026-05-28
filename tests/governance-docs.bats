#!/usr/bin/env bats

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WAYS="$REPO/docs/WAYS-OF-WORKING.md"
}

@test "routine registry names @tooming as the executor and planner owner" {
  run grep -F '| Executor | `trig_01CRtpmaS1scBQL74xKqmfvS` | @tooming |' "$WAYS"
  [ "$status" -eq 0 ]

  run grep -F '| Planner | `trig_015uWP3Hv1LTREpKzzkMkpUE` | @tooming |' "$WAYS"
  [ "$status" -eq 0 ]
}

@test "governance doc no longer uses the @maintainer placeholder" {
  run grep -F '@maintainer' "$WAYS"
  [ "$status" -eq 1 ]
}
