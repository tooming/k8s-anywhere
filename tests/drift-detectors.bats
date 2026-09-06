#!/usr/bin/env bats
# Tests for the drift detectors themselves — readme-check.sh and lab-ui-check.sh
# gate correctness via the PostToolUse hooks, so they need their own proof that
# they (a) pass on an in-sync tree and (b) actually FAIL on real drift. Each script
# takes a ROOT override, so we point it at golden fixture trees under tests/fixtures.
#
# This file is now FROZEN (mirroring tests/securitycontext.bats /
# tests/observability.bats / tests/networkpolicy.bats) — every new, unrelated
# drift-check script had been appending its own @test section here (24+ sections
# accumulated), the same "shared monolith multiple PRs append to" footgun those
# other files were split off to prevent. New drift-check coverage goes in its own
# tests/drift-<scope>.bats file; the drift-detectors-tests-check gate enforces this.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$REPO/tests/fixtures"
}

# --- readme-check ------------------------------------------------------------
@test "readme-check: passes on an in-sync fixture" {
  run env READMECHECK_ROOT="$FIX/readme-check/in-sync" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
}

@test "readme-check: fails when README names a make target that doesn't exist" {
  run env READMECHECK_ROOT="$FIX/readme-check/drift" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bogus"* ]]
}

@test "readme-check: passes on the real repo README.md" {
  run bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
}

@test "readme-check: fails when an ADR names a make target that doesn't exist" {
  run env READMECHECK_ROOT="$FIX/readme-check/adr-drift" bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bogus-adr-target"* ]]
}

# --- lab-ui-check --------------------------------------------------------------
# Used to also cross-check a Grafana "Lab UIs" dashboard panel — removed 2026-09-06
# (ADR-0041, observability stack removed with no replacement) along with grafana/.
# The README.md Endpoints-table cross-check below is independent of that panel and
# stays fully functional; these fixtures/tests were updated to match.
@test "lab-ui-check: passes when README.md's Endpoints table matches the IngressRoutes" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/in-sync" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 0 ]
}

@test "lab-ui-check: passes on the real repo's README.md + gitops IngressRoutes" {
  run bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 0 ]
}

@test "lab-ui-check: fails when a README.md Endpoints URL uses a non-front-door port" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/port-drift" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"front-door port :8000"* ]]
}

@test "lab-ui-check: fails when a routed UI is missing from README.md's Endpoints table" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/readme-missing" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING from README.md's Endpoints table"* ]]
}

@test "lab-ui-check: fails when README.md's Endpoints table has a stale row" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/readme-stale" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"stale row?"* ]]
}

# --- roadmap-check -----------------------------------------------------------
@test "roadmap-check: passes when ROADMAP has no inline planner note" {
  run env ROADMAPCHECK_ROOT="$FIX/roadmap-check/in-sync" bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 0 ]
}

@test "roadmap-check: fails on an inline dated planner note" {
  run env ROADMAPCHECK_ROOT="$FIX/roadmap-check/drift" bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"inline planner note"* ]]
}

@test "roadmap-check: passes on the real repo ROADMAP.md" {
  run bash "$REPO/scripts/roadmap-check.sh"
  [ "$status" -eq 0 ]
}

# --- markdown-links-check -----------------------------------------------------
@test "markdown-links-check: passes when every internal link resolves" {
  run env MDLINKS_ROOT="$FIX/markdown-links-check/in-sync" bash "$REPO/scripts/markdown-links-check.sh"
  [ "$status" -eq 0 ]
}

@test "markdown-links-check: fails on a broken relative link" {
  run env MDLINKS_ROOT="$FIX/markdown-links-check/drift" bash "$REPO/scripts/markdown-links-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"docs/moved.md"* ]]
}

@test "markdown-links-check: ignores external and anchor-only links" {
  run env MDLINKS_ROOT="$FIX/markdown-links-check/in-sync" bash "$REPO/scripts/markdown-links-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"example.com"* ]]
}

@test "markdown-links-check: passes on the real repo's tracked markdown" {
  run bash "$REPO/scripts/markdown-links-check.sh"
  [ "$status" -eq 0 ]
}

# --- git-fixture-isolation-check ---------------------------------------------
@test "git-fixture-isolation-check: passes when a fixture test unsets GIT_DIR" {
  run env GITFIX_CHECK_ROOT="$FIX/git-fixture-isolation-check/in-sync" bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 0 ]
}

@test "git-fixture-isolation-check: fails when a git-fixture test never unsets GIT_DIR" {
  run env GITFIX_CHECK_ROOT="$FIX/git-fixture-isolation-check/drift" bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"never unsets GIT_DIR"* ]]
}

@test "git-fixture-isolation-check: passes on the real repo tests/" {
  run bash "$REPO/scripts/git-fixture-isolation-check.sh"
  [ "$status" -eq 0 ]
}

# --- O2 PSS completeness gate -------------------------------------------------
# Prevent a future namespace.yaml from acquiring PSA enforce labels without
# securitycontext test coverage. Coverage is satisfied by EITHER an exact-match
# tests/securitycontext-<ns>.bats per-scope file OR any tests/securitycontext*.bats
# file (including the frozen monolith and combined-scope files like
# securitycontext-moto-ack-labgateway.bats) that references the namespace name.
# Namespace names are read from metadata.name in each namespace.yaml so paths like
# gitops/data/rabbitmq/namespace.yaml → "data" and
# gitops/ack/namespace.yaml → "ack-system" resolve correctly.
# Closes ROADMAP auto/o2-pss-coverage-loop.
@test "every PSA-labelled namespace has securitycontext test coverage (O2 recurrence guard)" {
  local fail=0
  local ns_file ns
  while IFS= read -r ns_file; do
    grep -q 'pod-security.kubernetes.io/enforce:' "$ns_file" || continue
    ns="$(grep -m1 '^  name:' "$ns_file" | awk '{print $2}')"
    [ -n "$ns" ] || continue
    # Exact-match per-scope file wins immediately
    if [ -f "$BATS_TEST_DIRNAME/securitycontext-${ns}.bats" ]; then
      continue
    fi
    # Broader check: any securitycontext-*.bats (incl. monolith + combined-scope) covers ns
    if grep -ql "$ns" "$BATS_TEST_DIRNAME"/securitycontext*.bats 2>/dev/null; then
      continue
    fi
    printf 'MISSING securitycontext coverage for namespace "%s" (file: %s)\n' \
      "$ns" "$ns_file" >&2
    fail=1
  done < <(find "$REPO/gitops" -name "namespace.yaml" | sort)
  [ "$fail" -eq 0 ]
}

# --- drift-detectors-tests-check ----------------------------------------------
# This file is now FROZEN (same shape as securitycontext.bats / observability.bats
# / networkpolicy.bats) — it had grown to 24+ unrelated drift-check sections with
# every new CI gate script appending its own @test block here. New drift-check
# coverage belongs in its own tests/drift-<scope>.bats file.
@test "drift-detectors-tests-check: passes when the monolith matches its snapshot" {
  run env DRIFTDET_TESTS_ROOT="$FIX/drift-detectors-tests-check/in-sync" bash "$REPO/scripts/drift-detectors-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "drift-detectors-tests-check: fails when a new @test is appended to the frozen monolith" {
  run env DRIFTDET_TESTS_ROOT="$FIX/drift-detectors-tests-check/drift" bash "$REPO/scripts/drift-detectors-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
}

@test "drift-detectors-tests-check: passes on the real repo tests/drift-detectors.bats" {
  run bash "$REPO/scripts/drift-detectors-tests-check.sh"
  [ "$status" -eq 0 ]
}
