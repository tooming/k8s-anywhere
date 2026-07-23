#!/usr/bin/env bats
# Tests for the CI-workflow-correctness drift checks — split out of the
# now-frozen tests/drift-detectors.bats monolith (see that file's header
# comment) into its own scope, per the drift-detectors-tests-check
# convention: new drift-check coverage goes in its own tests/drift-<scope>.bats
# file. Grouped together here because all three guard the same surface —
# .github/workflows/ci.yml staying correct and in parity with `make ci`.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- ci-parity-check -----------------------------------------------------------
@test "ci-parity-check: passes when make ci and ci.yml run the same scripts" {
  run env CIPARITY_ROOT="$FIX/ci-parity-check/in-sync" bash "$REPO/scripts/ci-parity-check.sh"
  [ "$status" -eq 0 ]
}

@test "ci-parity-check: fails when a script is only wired into make ci" {
  run env CIPARITY_ROOT="$FIX/ci-parity-check/drift" bash "$REPO/scripts/ci-parity-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bar-check.sh"* ]]
  [[ "$output" == *"never run in GitHub Actions"* ]]
}

@test "ci-parity-check: only scans the ci: target's recipe, not unrelated targets" {
  # The in-sync fixture's Makefile has an 'other:' target invoking
  # scripts/unrelated.sh — must never appear in either side's script set.
  run env CIPARITY_ROOT="$FIX/ci-parity-check/in-sync" bash "$REPO/scripts/ci-parity-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"unrelated.sh"* ]]
}

@test "ci-parity-check: passes on the real repo's Makefile and ci.yml" {
  run bash "$REPO/scripts/ci-parity-check.sh"
  [ "$status" -eq 0 ]
}

# --- ci.yml push trigger is scoped to main, not every branch -----------------------
# Regression guard for 2026-07-17 (PR #453/#456): `push: branches: ["**"]`
# alongside `pull_request:` ran the entire 7-job workflow twice per commit on
# every open PR branch (once per event) for zero coverage gain, since every
# branch here gets a PR immediately and `pull_request` already covers
# opened/synchronize/reopened. `push` must stay scoped to `main` only (the one
# case `pull_request` doesn't cover: a direct push straight to main).
@test "ci.yml push trigger is scoped to main only (no duplicate PR-branch runs)" {
  run awk '/^on:/{f=1;next} f && /^permissions:/{exit} f' "$REPO/.github/workflows/ci.yml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"branches: [main]"* ]]
  [[ "$output" != *'branches: ["**"]'* ]]
}

# --- ci.yml jobs all set an explicit timeout-minutes --------------------------------
# Regression guard for 2026-07-21: without an explicit job-level timeout,
# GitHub Actions' default 360-minute timeout applies, so a hung
# network-dependent install step (apt-get, a release-binary curl, the helm
# install script) can block a PR for hours instead of failing fast. Observed
# directly that day on PR #648: the unit/drift jobs sat in_progress for 20+
# minutes with zero progress across three separate attempts, needing a manual
# cancel+rerun each time. Every job must set its own timeout-minutes
# (job-level, not a single global default) so a future job added without one
# doesn't silently fall back to 360. Scoped to the `jobs:` section only — `on:`
# and `permissions:` also have 2-space-indented `key:` lines that would
# false-positive as job names otherwise.
@test "every ci.yml job sets an explicit timeout-minutes" {
  run awk '
    /^jobs:/{injobs=1}
    injobs && /^  [a-z-]+:$/{
      if (job) { if (!seen) { print "missing timeout-minutes: " job; bad=1 }; seen=0 }
      job=$1; next
    }
    injobs && /timeout-minutes:/{ seen=1 }
    END { if (job && !seen) { print "missing timeout-minutes: " job; bad=1 }; exit bad+0 }
  ' "$REPO/.github/workflows/ci.yml"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ci.yml job count matches its timeout-minutes count (one per job, no drift)" {
  jobs="$(awk '/^jobs:/{f=1;next} f' "$REPO/.github/workflows/ci.yml" | grep -cE '^  [a-z-]+:$')"
  timeouts="$(grep -cE '^    timeout-minutes:' "$REPO/.github/workflows/ci.yml")"
  [ "$jobs" -eq "$timeouts" ]
}
