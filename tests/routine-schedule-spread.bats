#!/usr/bin/env bats
# Recurrence guard for the 2026-07-16 scheduling change (maintainer request:
# "spread out the routines across the day"). Guards that routines.yaml's cron is
# spread across the day, not clustered in one window, once this change is applied
# to the live trigger (see routines/README.md "Changing a routine" — this file's
# content only takes effect on `main` once an interactive session's
# `RemoteTrigger update` call actually succeeds; it was refused in the 2026-07-16
# session that authored this, so this PR is expected to land separately/later).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROUTINES_YAML="$REPO/routines/routines.yaml"
}

@test "routines.yaml cron is present and well-formed" {
  run grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML"
  [ "$status" -eq 0 ]
}

@test "routines.yaml cron hour list spans at least 12 hours (spread, not clustered)" {
  cron_line="$(grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML" | head -1)"
  hours="$(echo "$cron_line" | sed -E 's/cron: "0 ([0-9,]+) \* \* \*"/\1/')"
  min=99
  max=-1
  IFS=',' read -ra HR <<< "$hours"
  for h in "${HR[@]}"; do
    [ "$h" -lt "$min" ] && min="$h"
    [ "$h" -gt "$max" ] && max="$h"
  done
  spread=$((max - min))
  [ "$spread" -ge 12 ] || { echo "cron hours $hours only span $spread hours — not spread across the day"; return 1; }
}

@test "routines.yaml no longer uses the old all-night clustered cron" {
  run grep -q '"0 21,22,23,0,1 \* \* \*"' "$ROUTINES_YAML"
  [ "$status" -eq 1 ]
}

@test "routines.yaml fires at most 4 times a day (account-wide free-quota cap, 1 slot shared out to easysportstream 2026-08-18)" {
  cron_line="$(grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML" | head -1)"
  hours="$(echo "$cron_line" | sed -E 's/cron: "0 ([0-9,]+) \* \* \*"/\1/')"
  count="$(echo "$hours" | tr ',' '\n' | grep -c .)"
  [ "$count" -eq 4 ]
}
