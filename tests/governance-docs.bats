#!/usr/bin/env bats

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WAYS="$REPO/docs/WAYS-OF-WORKING.md"
}

@test "routine registry names @tooming as the executor owner" {
  # Only one trigger is actually live (the rest were retired 2026-06-13 and
  # absorbed into the executor's fallback chain — see WAYS-OF-WORKING.md §1),
  # so the registry table has one row, not a separate row per former routine.
  run grep -F '| Executor | `trig_01XxtSdkPdRNjBfAidUXTwos` | @tooming |' "$WAYS"
  [ "$status" -eq 0 ]
}

@test "governance doc no longer uses the @maintainer placeholder" {
  run grep -F '@maintainer' "$WAYS"
  [ "$status" -eq 1 ]
}
