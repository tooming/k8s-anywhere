#!/usr/bin/env bats
# Recurrence guard for the 2026-07-16 scheduling change (maintainer request:
# "spread out the routines across the day"). Guards that routines.yaml's cron is
# spread across the day, not clustered in one window, once this change is applied
# to the live trigger (see routines/README.md "Changing a routine" — this file's
# content only takes effect on `main` once an interactive session's
# `RemoteTrigger update` call actually succeeds; it was refused in the 2026-07-16
# session that authored this, so this PR is expected to land separately/later).
#
# Numeric thresholds updated 2026-08-25 (found live: PR #1342/#1343 dropped this
# repo's own cron from 3->2 runs/day, hours "0,5", to free a third account-wide
# slot for a new toomingsolutions/skoor-ai executor trigger — see routines.yaml's own
# header comment for the full history of this repo's slot count shrinking
# 5->4->3->2 across three separate hand-offs to sibling-repo triggers — without
# updating this file's now-stale "at least 12 hours"/"exactly 3" assertions,
# breaking `make ci`'s `unit` job on every run since). The "spread across the
# day" invariant this file's title describes is now an ACCOUNT-WIDE property
# (5 fixed fire-times total spread across k8s-anywhere+easysportstream+
# keebridge+skoor-ai combined, per routines.yaml's own "Quota math" comment) —
# this repo's own remaining 2 slots can't individually span 12+ hours anymore,
# so the per-repo check below is scaled down to what's still a meaningful
# "not clustered in the same couple of hours" guard for a 2-value schedule,
# rather than dropped entirely.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROUTINES_YAML="$REPO/routines/routines.yaml"
}

@test "routines.yaml cron is present and well-formed" {
  run grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML"
  [ "$status" -eq 0 ]
}

@test "routines.yaml cron hour list spans at least 4 hours when it has more than one fire-time (spread, not clustered)" {
  # A single-hour cron (this repo dropped to 1 run/day on 2026-08-25 to fund
  # appforge-ci — see routines.yaml's header) has nothing to spread against
  # by itself; the "not clustered" invariant only means something once this
  # repo's own schedule has 2+ fire-times again. See this file's header for
  # why the invariant itself is now account-wide, not per-repo.
  cron_line="$(grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML" | head -1)"
  hours="$(echo "$cron_line" | sed -E 's/cron: "0 ([0-9,]+) \* \* \*"/\1/')"
  min=99
  max=-1
  IFS=',' read -ra HR <<< "$hours"
  for h in "${HR[@]}"; do
    [ "$h" -lt "$min" ] && min="$h"
    [ "$h" -gt "$max" ] && max="$h"
  done
  if [ "${#HR[@]}" -lt 2 ]; then
    skip "single fire-time ($hours) — spread invariant is vacuous for one value"
  fi
  spread=$((max - min))
  [ "$spread" -ge 4 ] || { echo "cron hours $hours only span $spread hours — not spread across the day"; return 1; }
}

@test "routines.yaml no longer uses the old all-night clustered cron" {
  run grep -q '"0 21,22,23,0,1 \* \* \*"' "$ROUTINES_YAML"
  [ "$status" -eq 1 ]
}

@test "routines.yaml's actual cron hour count matches its own declared 'Exactly N runs/day' policy comment" {
  # Derived from routines.yaml's own header comment instead of a second
  # hardcoded literal here: this is the actual fix for the 2026-08-25 drift
  # (see this file's header) — a hardcoded expected count in THIS file needed
  # a human to remember to update it every time routines.yaml's cron changed,
  # and that's exactly the step that got missed. Deriving the expectation from
  # routines.yaml's own "Exactly N runs/day" sentence instead makes this a
  # doc-vs-reality consistency check: it now fails if EITHER the cron or the
  # comment changes without the other, not just when this test file itself
  # falls behind.
  declared_count="$(grep -oE 'Exactly [0-9]+ runs?/day' "$ROUTINES_YAML" | tail -1 | grep -oE '[0-9]+')"
  [ -n "$declared_count" ] || { echo "no 'Exactly N runs/day' sentence found in $ROUTINES_YAML"; return 1; }

  cron_line="$(grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML" | head -1)"
  hours="$(echo "$cron_line" | sed -E 's/cron: "0 ([0-9,]+) \* \* \*"/\1/')"
  actual_count="$(echo "$hours" | tr ',' '\n' | grep -c .)"

  [ "$actual_count" -eq "$declared_count" ] || {
    echo "cron fires $actual_count times/day (hours: $hours) but routines.yaml's own comment declares \"Exactly $declared_count runs/day\" — one of the two is stale"
    return 1
  }
}

@test "docs/WAYS-OF-WORKING.md's Executor registry row cadence matches routines.yaml's actual cron" {
  # Found live 2026-08-27: routines.yaml's cron dropped 3->2->1 runs/day across
  # three same-day hand-offs to sibling-repo triggers (see routines.yaml's own
  # header comment), and each cut updated THIS bats file's assertions above
  # (which read routines.yaml's own comment) but never touched
  # docs/WAYS-OF-WORKING.md §1's registry table, which still hardcodes both a
  # fire-time list ("00:00/05:00/14:00 UTC") and a "(3/day)" count as free
  # prose with no mechanical link back to routines.yaml. Same drift class the
  # "actual cron hour count matches its own declared" test above already
  # guards for routines.yaml's *own* comment — this test closes the same gap
  # for WAYS-OF-WORKING.md's separate copy of the same fact.
  WOW="$REPO/docs/WAYS-OF-WORKING.md"
  [ -f "$WOW" ] || skip "docs/WAYS-OF-WORKING.md not found"

  # Executor's row is the one carrying its trigger_id from routines.yaml.
  trigger_id="$(grep -oE 'trigger_id: [A-Za-z0-9_]+' "$ROUTINES_YAML" | head -1 | awk '{print $2}')"
  [ -n "$trigger_id" ] || { echo "no trigger_id found in $ROUTINES_YAML"; return 1; }
  row="$(grep -F "$trigger_id" "$WOW")"
  [ -n "$row" ] || { echo "no WAYS-OF-WORKING.md registry row cites trigger_id $trigger_id"; return 1; }

  # Same hour-derivation as the test above.
  cron_line="$(grep -oE 'cron: "[^"]+"' "$ROUTINES_YAML" | head -1)"
  hours="$(echo "$cron_line" | sed -E 's/cron: "0 ([0-9,]+) \* \* \*"/\1/')"
  actual_count="$(echo "$hours" | tr ',' '\n' | grep -c .)"

  # The row's Cadence cell states the count as "(N/day)".
  row_count="$(echo "$row" | grep -oE '\([0-9]+/day\)' | grep -oE '[0-9]+')"
  [ -n "$row_count" ] || { echo "WAYS-OF-WORKING.md's Executor row has no '(N/day)' count to check"; return 1; }
  [ "$actual_count" -eq "$row_count" ] || {
    echo "routines.yaml's cron fires $actual_count times/day (hours: $hours) but docs/WAYS-OF-WORKING.md's Executor row declares ($row_count/day) — the table is stale, fix the row to match routines.yaml"
    return 1
  }

  # The row also spells out the fire-times themselves (e.g. "00:00 UTC" or
  # "00:00/05:00/14:00 UTC") — check that too, not just the count.
  expected_times="$(echo "$hours" | awk -F',' '{for(i=1;i<=NF;i++) printf "%s%02d:00", (i>1?"/":""), $i}')"
  case "$row" in
    *"$expected_times UTC"*) ;;
    *)
      echo "routines.yaml's cron implies fire-times \"$expected_times UTC\" but docs/WAYS-OF-WORKING.md's Executor row doesn't contain that exact string — the table's fire-time list is stale"
      return 1
      ;;
  esac
}
