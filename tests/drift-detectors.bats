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

@test "readme-check: passes on the real repo README.md" {
  run bash "$REPO/scripts/readme-check.sh"
  [ "$status" -eq 0 ]
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

# --- observability-tests-check -----------------------------------------------
@test "observability-tests-check: passes when the monolith matches its snapshot" {
  run env OBSV_TESTS_ROOT="$FIX/observability-tests-check/in-sync" bash "$REPO/scripts/observability-tests-check.sh"
  [ "$status" -eq 0 ]
}

@test "observability-tests-check: fails when a new @test is appended to the frozen monolith" {
  run env OBSV_TESTS_ROOT="$FIX/observability-tests-check/drift" bash "$REPO/scripts/observability-tests-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FROZEN"* ]]
}

@test "observability-tests-check: passes on the real repo tests/observability.bats" {
  run bash "$REPO/scripts/observability-tests-check.sh"
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

@test "mimir-readonly-root-check: FAILS when the Deployment has zero writable (emptyDir/PVC) volumeMounts" {
  # Regression for a real bug: mapfile read the check's empty-set output as one
  # empty-string array element (not zero), which made under_writable()'s "$m"/*
  # glob (m="") match literally any absolute path -- silently reporting every
  # write path as "writable" instead of catching a Deployment with no writable
  # mounts at all. Fixed by only printing the mount list when it's non-empty.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/no-writable-mounts" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"declares no writable"* ]]
}

@test "mimir-readonly-root-check: FAILS when the ConfigMap has no data[\"mimir.yaml\"] key" {
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/no-configmap-data" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *'no data["mimir.yaml"]'* ]]
}

@test "mimir-readonly-root-check: FAILS when a required setting is set but not under a writable mount" {
  # Distinct branch from "unset" above: ruler.rule_path IS set here, just to a
  # read-only (configMap) mount instead of a writable one.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/required-not-writable" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ruler.rule_path (/etc/mimir/ruler) is not under a writable mount"* ]]
}

@test "mimir-readonly-root-check: FAILS when an arbitrary config path lands off the writable mounts" {
  # Exercises the step-2 generic "/..." path scan (not one of the two hardcoded
  # REQUIRED settings) -- compactor.data_dir here, an ordinary absolute value.
  run env MIMIR_RWCHECK_ROOT="$FIX/mimir-readonly-root-check/arbitrary-path-not-writable" \
          bash "$REPO/scripts/mimir-readonly-root-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"config path /etc/mimir/compactor is not under a writable mount"* ]]
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

# --- idle-issue-guard-check ---------------------------------------------------
# ROADMAP rule #9 (revised 2026-07-14): "executor/session idle — no work" is a
# forbidden outcome, full stop — every run ships a PR instead. This guard used
# to require fallback-chain evidence before allowing an idle issue through;
# idle issues piled up anyway (#52, #56, #57, #76, #89, #121, #262, #390, #398)
# so the maintainer ended the pattern outright — the guard now blocks any idle
# declaration unconditionally, evidence or not.
@test "idle-issue-guard-check: passes on an unrelated issue title/body" {
  run env IDLEGUARD_TITLE="fix flaky test" IDLEGUARD_BODY="unrelated body" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: FAILS on an idle claim with no fallback-chain evidence" {
  run env IDLEGUARD_TITLE="executor idle — needs work" IDLEGUARD_BODY="nothing to build this run" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
}

@test "idle-issue-guard-check: FAILS even when make ci + CHARTER evidence is present (idle is blocked unconditionally now)" {
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="ran make ci locally, all green. Cross-checked CHARTER.md Objectives against ROADMAP.md's checked items, no ungroomed gap found." \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
}

@test "idle-issue-guard-check: passes when closing an idle issue, even though the closing body discusses 'idle'" {
  # Regression: closing issue #398 with a body explaining the new no-idle-issues
  # policy ("idle issues ... are now forbidden ...") re-tripped the same guard
  # it was satisfying, since "idle" appears as a standalone word outside any
  # hyphenated compound. Closing is the resolution, not the violation.
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="closing this per your feedback: idle issues are now a forbidden outcome, not a gated-but-acceptable one." \
      IDLEGUARD_STATE="closed" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: does not self-trigger on a comment merely discussing the guard" {
  # Regression: a [self-review] comment on the PR introducing this guard tripped
  # the check just for naming its own script (idle-issue-guard-check.sh contains
  # "idle") and for saying "idle-titled". Discussing the feature must not read
  # as an idle/no-work claim. (add_issue_comment has no title field.)
  run env IDLEGUARD_TITLE="" \
      IDLEGUARD_BODY="Added scripts/idle-issue-guard-check.sh and scripts/idle-issue-guard-hook.sh, wired as a PostToolUse hook that nudges when an idle-titled issue/comment is missing evidence." \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: does not self-trigger on a [self-review] comment discussing 'idle' as standalone prose" {
  # Regression (2026-07-16): the self-review comment for the PR that corrected
  # STEP 8's stop condition discussed "idle cycle" / "idle issue" as standalone
  # prose (not the hyphenated-compound shape the scrub above already handles)
  # while explaining the fix, and tripped this guard even though it reported
  # real, already-shipped work on an existing PR. A [self-review] comment can
  # never legitimately be an idle *declaration* — it always follows a PR that
  # already has a real diff.
  run env IDLEGUARD_TITLE="" \
      IDLEGUARD_BODY="[self-review]
Gate integrity: ✅
An idle cycle is never a reason to stop the run; only credit exhaustion is." \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 0 ]
}

@test "idle-issue-guard-check: still FAILS an idle declaration without the [self-review] prefix" {
  # The exemption above must be narrow — it keys off the literal body prefix,
  # not merely the presence of the word "self-review" or a PR context.
  run env IDLEGUARD_TITLE="executor idle — needs work" \
      IDLEGUARD_BODY="no actionable work found this run" \
      bash "$REPO/scripts/idle-issue-guard-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden"* ]]
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
