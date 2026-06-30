#!/usr/bin/env bats
# Tests for the drift detectors themselves — readme-check.sh and lab-ui-check.sh
# gate correctness via the PostToolUse hooks, so they need their own proof that
# they (a) pass on an in-sync tree and (b) actually FAIL on real drift. Each script
# takes a ROOT override, so we point it at golden fixture trees under tests/fixtures.

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

# --- securitycontext-tests-check ---------------------------------------------
@test "securitycontext-tests-check: passes when the monolith matches its snapshot" {
  run env SECCTX_TESTS_ROOT="$FIX/securitycontext-tests-check/in-sync" bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "securitycontext-tests-check: fails when a new @test is appended to the frozen monolith" {
  run env SECCTX_TESTS_ROOT="$FIX/securitycontext-tests-check/drift" bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
}

@test "securitycontext-tests-check: passes on the real repo tests/securitycontext.bats" {
  run bash "$REPO/scripts/securitycontext-tests-check.sh"
  [ "$status" -eq 0 ]
}

# --- networkpolicy-tests-check -----------------------------------------------
@test "networkpolicy-tests-check: passes when the monolith is baseline-only" {
  run env NETPOL_TESTS_ROOT="$FIX/networkpolicy-tests-check/in-sync" bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-tests-check: fails when a per-namespace overlay test leaks into the monolith" {
  run env NETPOL_TESTS_ROOT="$FIX/networkpolicy-tests-check/drift" bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"namespace overlay"* ]]
}

@test "networkpolicy-tests-check: passes on the real repo tests/networkpolicy.bats" {
  run bash "$REPO/scripts/networkpolicy-tests-check.sh"
  [ "$status" -eq 0 ]
}

# --- yq-raw-check ------------------------------------------------------------
@test "yq-raw-check: passes when no bats test calls yq directly" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/in-sync" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 0 ]
}

@test "yq-raw-check: fails when a bats test uses a bare yq call" {
  run env YQRAW_CHECK_ROOT="$FIX/yq-raw-check/drift" bash "$REPO/scripts/yq-raw-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bare 'yq'"* ]]
}

@test "yq-raw-check: passes on the real repo tests/" {
  run bash "$REPO/scripts/yq-raw-check.sh"
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

# --- routines-author-check ---------------------------------------------------
# The executor (auto/* branch, cloud "Claude <noreply@anthropic.com>" commits) has
# no RemoteTrigger tool, so it can't apply a routine change to the live trigger.
# This guard fails when an executor-authored change edits a routine file. Branch
# and changed-file list are injected via env so the logic is testable without a
# live git history.

@test "routines-author-check: FAILS when an auto/* change edits a routine prompt" {
  run env ROUTINES_AUTHOR_BRANCH="auto/foo" \
          ROUTINES_AUTHOR_FILES=$'routines/executor.prompt.md\ngitops/x.yaml' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"executor-authored change"* ]]
  [[ "$output" == *"routines/executor.prompt.md"* ]]
}

@test "routines-author-check: FAILS when an auto/* change edits routines.yaml" {
  run env ROUTINES_AUTHOR_BRANCH="auto/bar" \
          ROUTINES_AUTHOR_FILES=$'routines.yaml' \
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

@test "routines-author-check: passes when an INTERACTIVE branch edits a routine prompt (it can apply)" {
  run env ROUTINES_AUTHOR_BRANCH="chore/edit-routines" \
          ROUTINES_AUTHOR_FILES=$'routines/executor.prompt.md' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
}

@test "routines-author-check: FAILS on a cloud-authored routine edit even off the auto/* prefix" {
  run env ROUTINES_AUTHOR_BRANCH="chore/sneaky" \
          ROUTINES_AUTHOR_IS_CLOUD=1 \
          ROUTINES_AUTHOR_FILES=$'routines/planner.prompt.md' \
          bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cloud identity"* ]]
}

@test "routines-author-check: passes on the real repo (this branch makes no routine edits)" {
  run bash "$REPO/scripts/routines-author-check.sh"
  [ "$status" -eq 0 ]
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

# --- mimir-readonly-root-check -----------------------------------------------
@test "mimir-readonly-root-check: passes when every write path is on a writable mount" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/in-sync" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 0 ]
}

@test "mimir-readonly-root-check: FAILS when activity_tracker.filepath is unset (read-only-root default)" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/drift" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"writable mount"* ]]
}

@test "mimir-readonly-root-check: passes on the real repo mimir manifests" {
  run bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 0 ]
}

# --- yq variant portability guard --------------------------------------------
# mikefarah/yq (Go) and kislyuk/python-yq (jq wrapper) disagree on -o=json and
# tag==""  syntax. Scripts using mikefarah-only flags produce empty output on a
# kislyuk/python-yq installation (errors silently swallowed by 2>/dev/null),
# turning assertions into false-negatives or false-positives. This bit the
# mimir-readonly-root-check.sh (chore/fix-mimir-ci-check-yq-compat). Use
# python3/PyYAML instead (portable; already the fix in that script).
@test "no check script uses yq -o=json (mikefarah-only flag, breaks on kislyuk/python-yq)" {
  run grep -rl 'yq -o=json' "$REPO/scripts/"
  # grep exits 1 when no files match — that is the passing condition
  [ "$status" -eq 1 ]
}
