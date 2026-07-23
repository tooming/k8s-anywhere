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

# --- lab-ui-check ------------------------------------------------------------
@test "lab-ui-check: passes when the panel matches the HTTPRoutes" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/in-sync" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 0 ]
}

@test "lab-ui-check: fails when a routed UI is missing from the panel" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/drift" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING from the Lab UIs panel"* ]]
}

@test "lab-ui-check: passes on the real repo's Lab UIs panel + gitops HTTPRoutes" {
  run bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 0 ]
}

@test "lab-ui-check: fails when a panel URL uses a non-front-door port" {
  run env LABUICHECK_ROOT="$FIX/lab-ui-check/port-drift" bash "$REPO/scripts/lab-ui-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"front-door port :8000"* ]]
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

# --- ci.yml push trigger is scoped to main, not every branch -----------------
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

# --- ci.yml jobs all set an explicit timeout-minutes --------------------------
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

# --- routines-author-check ---------------------------------------------------
# The executor (auto/* branch, cloud "Claude <noreply@anthropic.com>" commits) has
# no RemoteTrigger tool, so it can't apply a routines.yaml change to the live
# trigger. This guard fails when an executor-authored change edits routines.yaml.
# Branch and changed-file list are injected via env so the logic is testable
# without a live git history.
#
# Since the 2026-07-15 pointer architecture, routines/*.prompt.md files are read
# live every run and never baked into a trigger — editing one carries zero
# live-drift risk, so this guard no longer protects them at all (any session,
# including the executor, may edit them freely). Only routines.yaml still drives
# live trigger state via the API, so it remains the one protected file.

@test "routines-author-check: passes when an auto/* change edits a routine prompt (no longer baked into any trigger)" {
  run env ROUTINES_AUTHOR_BRANCH="auto/foo" \
          ROUTINES_AUTHOR_FILES=$'routines/executor.prompt.md\ngitops/x.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: FAILS when an auto/* change edits routines.yaml" {
  run env ROUTINES_AUTHOR_BRANCH="auto/bar" \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"routines.yaml"* ]]
}

@test "routines-author-check: passes when an auto/* change touches no routine files" {
  run env ROUTINES_AUTHOR_BRANCH="auto/foo" \
          ROUTINES_AUTHOR_FILES=$'gitops/x.yaml\ndocs/done/2026-06-25-foo.md' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: passes when an INTERACTIVE branch edits routines.yaml (it can apply)" {
  run env ROUTINES_AUTHOR_BRANCH="chore/edit-routines" \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: FAILS on a cloud-authored routines.yaml edit even off the auto/* prefix" {
  run env ROUTINES_AUTHOR_BRANCH="chore/sneaky" \
          ROUTINES_AUTHOR_IS_CLOUD=1 \
          ROUTINES_AUTHOR_FILES=$'routines/routines.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cloud identity"* ]]
}

@test "routines-author-check: passes on the real repo (this branch makes no routine edits)" {
  run bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

# --- routines-check ------------------------------------------------------------
# Regression: the file has always lived at routines/routines.yaml, but the script
# once globbed "$ROOT/routines.yaml" (no such file) so drift on it was silently
# never detected. Assert it's actually tracked now.
@test "routines-check: tracks routines/routines.yaml, not a nonexistent top-level path" {
  run bash "$REPO/scripts/routines-check.sh"
  [[ "$output" != *"routines.yaml is not in .routines-applied"* ]]
}

# --- helm-chart-pin-check ----------------------------------------------------
# Resolved offline via a stub resolver (CHARTPIN_RESOLVER) so the suite never hits
# the network; helm's real "not found" vs "cannot be reached" strings are verified
# by hand. STUB="$FIX/helm-chart-pin/resolver-stub.sh".
@test "helm-chart-pin-check: passes when every chart pin resolves (git-sourced apps ignored)" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/in-sync" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"good-chart"* ]]
}

@test "helm-chart-pin-check: FAILS when a chart pins a version missing from a reachable repo" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/drift" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad-pin"* ]]
  [[ "$output" == *"NOT found"* ]]
}

@test "helm-chart-pin-check: SKIPS (does not fail) when the repo is unreachable" {
  run env CHARTPINCHECK_ROOT="$FIX/helm-chart-pin/unreachable" \
          CHARTPIN_RESOLVER="$FIX/helm-chart-pin/resolver-stub.sh" \
          bash "$REPO/scripts/helm-chart-pin-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"offline-repo"* ]]
  [[ "$output" == *"skipped"* ]]
}

# --- argocd-crd-ssa-check ----------------------------------------------------
# Rendered offline via a stub renderer (CRDSSA_RENDERER) so the suite never pulls a
# real chart; the stub emits an oversized CRD for "big-crd-chart" and a tiny one for
# "small-crd-chart". This proves the size-vs-SSA logic without helm/network.
@test "argocd-crd-ssa-check: passes when an oversized-CRD Application uses ServerSideApply" {
  run env CRDSSA_CHECK_ROOT="$FIX/argocd-crd-ssa/in-sync" \
          CRDSSA_RENDERER="$FIX/argocd-crd-ssa/renderer-stub.sh" \
          bash "$REPO/scripts/argocd-crd-ssa-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bigcrd-app: SSA enabled"* ]]
}

@test "argocd-crd-ssa-check: FAILS when an oversized-CRD Application lacks ServerSideApply" {
  run env CRDSSA_CHECK_ROOT="$FIX/argocd-crd-ssa/drift" \
          CRDSSA_RENDERER="$FIX/argocd-crd-ssa/renderer-stub.sh" \
          bash "$REPO/scripts/argocd-crd-ssa-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bigcrd-app"* ]]
  [[ "$output" == *"ServerSideApply"* ]]
}

# --- rollouts-plugin-list-check ----------------------------------------------
@test "rollouts-plugin-list-check: passes when plugin values are YAML lists" {
  run env ROLLOUTS_PLUGIN_CHECK_ROOT="$FIX/rollouts-plugin-list-check/in-sync" \
          bash "$REPO/scripts/rollouts-plugin-list-check.sh"
  [ "$status" -eq 0 ]
}

@test "rollouts-plugin-list-check: FAILS when a plugin value is a block-scalar string" {
  run env ROLLOUTS_PLUGIN_CHECK_ROOT="$FIX/rollouts-plugin-list-check/drift" \
          bash "$REPO/scripts/rollouts-plugin-list-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"must be a YAML list"* ]]
}

@test "rollouts-plugin-list-check: passes on the real repo gitops" {
  run bash "$REPO/scripts/rollouts-plugin-list-check.sh"
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
# gitops/longhorn/namespace.yaml → "longhorn-system" resolve correctly.
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
