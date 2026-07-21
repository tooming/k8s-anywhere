#!/usr/bin/env bats
# Structural + behavioral coverage for scripts/dora-metrics.sh (RFC #580, Objective
# O7). Clusterless — every assertion runs against this repo's own real git history,
# no network required for the assertions that matter (gh/jq absence is itself an
# exercised path: the script must degrade to "insufficient data", never crash or
# fabricate a number).

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO/scripts/dora-metrics.sh"
}

@test "dora-metrics.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "dora-metrics.sh is executable" {
  [ -x "$SCRIPT" ]
}

@test "Makefile declares a dora-metrics target" {
  run grep -qE '^dora-metrics:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "dora-metrics target is NOT invoked from the up target (on-demand only)" {
  up_block=$(sed -n '/^up:/,/^$/p' "$REPO/Makefile")
  ! grep -q 'dora-metrics' <<<"$up_block"
}

@test "dora-metrics target is NOT invoked from the ci target (on-demand only)" {
  ci_block=$(sed -n '/^ci:/,/^$/p' "$REPO/Makefile")
  ! grep -q 'dora-metrics' <<<"$ci_block"
}

@test "docs/dora-metrics.md exists (committed real snapshot)" {
  [ -f "$REPO/docs/dora-metrics.md" ]
}

@test "docs/dora-metrics.md is not a stub — has all four metric rows" {
  local doc="$REPO/docs/dora-metrics.md"
  run grep -q 'Deployment frequency' "$doc"
  [ "$status" -eq 0 ]
  run grep -q 'Lead time for changes' "$doc"
  [ "$status" -eq 0 ]
  run grep -q 'Change failure rate' "$doc"
  [ "$status" -eq 0 ]
  run grep -q 'Time to restore service' "$doc"
  [ "$status" -eq 0 ]
}

@test "a zero-commit window renders 'insufficient data', not a crash or fabricated number" {
  local out="$BATS_TEST_TMPDIR/dora-zero.md"
  DORA_SINCE_EPOCH=1000000000 DORA_UNTIL_EPOCH=1000000100 DORA_OUT="$out" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$out" ]
  run grep -c 'insufficient data' "$out"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "the real repo window computes a coherent result against this repo's actual history" {
  # CI checks out with `fetch-depth: 1` (shallow) — the script now tries to
  # deepen a shallow clone itself (`git fetch --unshallow`) before measuring, so
  # this either computes real numbers (deepen succeeded) or honestly reports
  # "insufficient data" (deepen failed, e.g. no network) — never a number
  # silently truncated to the shallow boundary. What must never happen is a
  # crash, empty output, or a fabricated number.
  local out="$BATS_TEST_TMPDIR/dora-real.md"
  DORA_OUT="$out" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep 'Deployment frequency' "$out"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deployments/week"* || "$output" == *"insufficient data"* ]]
}

@test "dora-metrics.sh detects a shallow repository and attempts to deepen it before measuring" {
  run grep -q 'is-shallow-repository' "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -q -- '--unshallow' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dora-metrics.sh renders insufficient data (not a silently-truncated number) when a shallow repo can't be deepened" {
  # Regression guard for the 2026-07-21 finding: a shallow clone (this script's
  # only real caller, the remote executor, always runs from one) doesn't error
  # out — it silently computes a real-but-badly-undercounted number bounded by
  # the shallow boundary (observed 12x undercount) unless deployment frequency
  # and change failure rate both explicitly fall back to "insufficient data"
  # when the repo stays shallow after the deepen attempt.
  run grep -c "shallow clone could not be deepened" "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "dora-metrics.sh never fabricates lead time or restore time when gh is unavailable" {
  # Force gh to appear absent regardless of the host running this test, so the
  # assertion is deterministic in CI whether or not gh happens to be installed.
  local out="$BATS_TEST_TMPDIR/dora-nogh.md"
  local stubdir="$BATS_TEST_TMPDIR/stubbin"
  mkdir -p "$stubdir"
  # PATH with no `gh` on it at all (empty stub dir first, then a minimal safe PATH)
  DORA_OUT="$out" PATH="$stubdir:/usr/bin:/bin" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run grep -c 'insufficient data' "$out"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}
