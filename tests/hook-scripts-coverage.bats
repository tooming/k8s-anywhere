#!/usr/bin/env bats
# Structural coverage for the PostToolUse/SessionStart hook scripts that had zero
# bats coverage: adr-context-hook.sh, argocd-crd-ssa-sync-hook.sh,
# helm-chart-pin-sync-hook.sh, lab-ui-sync-hook.sh, mimir-readonly-root-sync-hook.sh,
# networkpolicy-tests-sync-hook.sh, observability-tests-sync-hook.sh,
# readme-sync-hook.sh, roadmap-sync-hook.sh, rollouts-plugin-list-sync-hook.sh,
# routines-sync-hook.sh, securitycontext-tests-sync-hook.sh, yq-raw-sync-hook.sh.
#
# Every other drift-detector gate (helm-chart-pin-check, roadmap-check, ...) has
# both a `make ci` step AND a bats file for the check script itself — but the
# PostToolUse hooks that locally nudge on the *same* condition (filtering by
# tool_input.file_path, then delegating to the check script) were untested. A
# broken case/esac filter or a wrong jq path would silently stop nudging without
# make ci ever catching it (make ci only exercises the check scripts, not the
# hooks). Mirrors the existing tests/adr-guard.bats / tests/commit-reminder-hook.bats
# / tests/merge-ci-gate-hook.bats pattern: feed a JSON payload on stdin, assert the
# exit code (0 = silent, 2 = nudge shown).
#
# Fully hermetic: no cluster, no network required for logic assertions (the two
# hooks that delegate to network-tolerant checks — argocd-crd-ssa,
# helm-chart-pin — degrade to a guaranteed exit 0 skip/pass offline, so those
# assertions hold either way).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

# --- adr-context-hook.sh (SessionStart; no stdin payload) --------------------

@test "adr-context-hook: exits 0" {
  run bash "$REPO/scripts/adr-context-hook.sh"
  [ "$status" -eq 0 ]
}

@test "adr-context-hook: prints the binding-ADRs banner" {
  run bash "$REPO/scripts/adr-context-hook.sh"
  [[ "$output" == *"BINDING"* ]]
}

@test "adr-context-hook: lists a known ADR decision (ADR-0002 Garage, not MinIO)" {
  run bash "$REPO/scripts/adr-context-hook.sh"
  [[ "$output" == *"Garage"* ]]
}

# --- argocd-crd-ssa-sync-hook.sh ----------------------------------------------

@test "argocd-crd-ssa-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/argocd-crd-ssa-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "argocd-crd-ssa-sync-hook: non-YAML path exits 0 (filtered out)" {
  run bash "$REPO/scripts/argocd-crd-ssa-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "argocd-crd-ssa-sync-hook: a real oversized-CRD Application that already sets SSA exits 0" {
  # kyverno.yaml bundles the ~650KB clusterpolicies CRD and is the reason this
  # guard exists — it already sets ServerSideApply=true.
  run bash "$REPO/scripts/argocd-crd-ssa-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "argocd-crd-ssa-sync-hook: an oversized-CRD Application without ServerSideApply exits 2 (drift)" {
  # The hook exits 0 for any file_path under tests/fixtures/ (that guard exists so
  # editing the deliberately-broken fixtures doesn't self-nag) — so the drift fixture
  # is copied outside that tree before invoking the hook, otherwise this test would
  # pass even if the drift-detection logic were broken.
  cp "$REPO/tests/fixtures/argocd-crd-ssa/drift/big-app.yaml" "$BATS_TEST_TMPDIR/big-app.yaml"
  run env CRDSSA_RENDERER="$REPO/tests/fixtures/argocd-crd-ssa/renderer-stub.sh" \
      bash "$REPO/scripts/argocd-crd-ssa-sync-hook.sh" <<<"$(mk_payload "$BATS_TEST_TMPDIR/big-app.yaml")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"bigcrd-app"* ]]
}

# --- helm-chart-pin-sync-hook.sh ----------------------------------------------

@test "helm-chart-pin-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/helm-chart-pin-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "helm-chart-pin-sync-hook: non-Application yaml exits 0 (filtered out)" {
  run bash "$REPO/scripts/helm-chart-pin-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml")"
  [ "$status" -eq 0 ]
}

@test "helm-chart-pin-sync-hook: a real chart-pinned Application exits 0 (valid pin, or network-tolerant skip)" {
  run bash "$REPO/scripts/helm-chart-pin-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "helm-chart-pin-sync-hook: a chart pin missing from a reachable repo exits 2 (drift)" {
  run env CHARTPIN_RESOLVER="$REPO/tests/fixtures/helm-chart-pin/resolver-stub.sh" \
      bash "$REPO/scripts/helm-chart-pin-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/fixtures/helm-chart-pin/drift/gitops/apps.yaml")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"bad-pin"* ]]
}

# --- lab-ui-sync-hook.sh -------------------------------------------------------

@test "lab-ui-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/lab-ui-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "lab-ui-sync-hook: unrelated gitops yaml with no HTTPRoute exits 0 (filtered out)" {
  run bash "$REPO/scripts/lab-ui-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "lab-ui-sync-hook: stack-health.json dashboard (currently in sync) exits 0" {
  run bash "$REPO/scripts/lab-ui-sync-hook.sh" <<<"$(mk_payload "$REPO/grafana/dashboards/stack-health.json")"
  [ "$status" -eq 0 ]
}

@test "lab-ui-sync-hook: a real HTTPRoute manifest (currently in sync) exits 0" {
  run bash "$REPO/scripts/lab-ui-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/tidb-demo/route.yaml")"
  [ "$status" -eq 0 ]
}

# --- mimir-readonly-root-sync-hook.sh ------------------------------------------

@test "mimir-readonly-root-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/mimir-readonly-root-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "mimir-readonly-root-sync-hook: a file outside gitops/observability/mimir/ exits 0 (filtered out)" {
  run bash "$REPO/scripts/mimir-readonly-root-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/observability/loki/deployment.yaml")"
  [ "$status" -eq 0 ]
}

@test "mimir-readonly-root-sync-hook: real mimir manifest (write paths already on a writable mount) exits 0" {
  run bash "$REPO/scripts/mimir-readonly-root-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/observability/mimir/configmap.yaml")"
  [ "$status" -eq 0 ]
}

# --- networkpolicy-tests-sync-hook.sh ------------------------------------------

@test "networkpolicy-tests-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/networkpolicy-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/observability.bats")"
  [ "$status" -eq 0 ]
}

@test "networkpolicy-tests-sync-hook: tests/networkpolicy.bats (currently baseline-only) exits 0" {
  run bash "$REPO/scripts/networkpolicy-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/networkpolicy.bats")"
  [ "$status" -eq 0 ]
}

# --- observability-tests-sync-hook.sh ------------------------------------------

@test "observability-tests-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/observability-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/networkpolicy.bats")"
  [ "$status" -eq 0 ]
}

@test "observability-tests-sync-hook: tests/observability.bats (currently frozen/compliant) exits 0" {
  run bash "$REPO/scripts/observability-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/observability.bats")"
  [ "$status" -eq 0 ]
}

# --- readme-sync-hook.sh --------------------------------------------------------

@test "readme-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/readme-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "readme-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/readme-sync-hook.sh" <<<"$(mk_payload "$REPO/CHARTER.md")"
  [ "$status" -eq 0 ]
}

@test "readme-sync-hook: Makefile (README currently in sync) exits 0" {
  run bash "$REPO/scripts/readme-sync-hook.sh" <<<"$(mk_payload "$REPO/Makefile")"
  [ "$status" -eq 0 ]
}

@test "readme-sync-hook: a real gitops/platform Application (README currently in sync) exits 0" {
  run bash "$REPO/scripts/readme-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

# --- roadmap-sync-hook.sh --------------------------------------------------------

@test "roadmap-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/roadmap-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "roadmap-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/roadmap-sync-hook.sh" <<<"$(mk_payload "$REPO/CHARTER.md")"
  [ "$status" -eq 0 ]
}

@test "roadmap-sync-hook: ROADMAP.md (no inline planner note currently) exits 0" {
  run bash "$REPO/scripts/roadmap-sync-hook.sh" <<<"$(mk_payload "$REPO/ROADMAP.md")"
  [ "$status" -eq 0 ]
}

# --- markdown-links-sync-hook.sh --------------------------------------------------

@test "markdown-links-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/markdown-links-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "markdown-links-sync-hook: unrelated (non-.md) file exits 0 (filtered out)" {
  run bash "$REPO/scripts/markdown-links-sync-hook.sh" <<<"$(mk_payload "$REPO/Makefile")"
  [ "$status" -eq 0 ]
}

@test "markdown-links-sync-hook: a real .md file (links currently resolve) exits 0" {
  run bash "$REPO/scripts/markdown-links-sync-hook.sh" <<<"$(mk_payload "$REPO/CHARTER.md")"
  [ "$status" -eq 0 ]
}

# --- rollouts-plugin-list-sync-hook.sh -------------------------------------------

@test "rollouts-plugin-list-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/rollouts-plugin-list-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "rollouts-plugin-list-sync-hook: Application yaml with no plugin keys exits 0 (filtered out)" {
  run bash "$REPO/scripts/rollouts-plugin-list-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/kyverno.yaml")"
  [ "$status" -eq 0 ]
}

@test "rollouts-plugin-list-sync-hook: real argo-rollouts Application (plugin values already YAML lists) exits 0" {
  run bash "$REPO/scripts/rollouts-plugin-list-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/platform/argo-rollouts.yaml")"
  [ "$status" -eq 0 ]
}

@test "rollouts-plugin-list-sync-hook: a block-scalar (string) plugin value exits 2" {
  cat >"$BATS_TEST_TMPDIR/bad-rollout-app.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-rollouts
spec:
  source:
    helm:
      valuesObject:
        controller:
          trafficRouterPlugins: |
            - name: argoproj-labs/gatewayAPI
YAML
  run bash "$REPO/scripts/rollouts-plugin-list-sync-hook.sh" <<<"$(mk_payload "$BATS_TEST_TMPDIR/bad-rollout-app.yaml")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be a YAML list"* || "$output" == *"unmarshal"* ]]
}

# --- routines-sync-hook.sh (fixture-tree copy: ROOT is BASH_SOURCE-relative, ---
# --- not env-overridable, so the hook + fixture .routines-applied are copied ---
# --- into an isolated tmp tree — mirrors tests/fixtures/routines-check/*) ------

setup_routines_fixture() {
  FIXROOT="$BATS_TEST_TMPDIR/routines-fixture"
  mkdir -p "$FIXROOT/scripts" "$FIXROOT/routines"
  cp "$REPO/scripts/routines-sync-hook.sh" "$FIXROOT/scripts/"
}

@test "routines-sync-hook: unrelated file path exits 0" {
  setup_routines_fixture
  run bash "$FIXROOT/scripts/routines-sync-hook.sh" <<<"$(mk_payload "$FIXROOT/routines/foo.prompt.md")"
  [ "$status" -eq 0 ]
}

@test "routines-sync-hook: routines.yaml hash matches the snapshot (in sync) exits 0" {
  setup_routines_fixture
  printf 'name: foo\n' >"$FIXROOT/routines/routines.yaml"
  sha="$(shasum -a 256 "$FIXROOT/routines/routines.yaml" | awk '{print $1}')"
  printf 'routines/routines.yaml sha256=%s\n' "$sha" >"$FIXROOT/.routines-applied"
  run bash "$FIXROOT/scripts/routines-sync-hook.sh" <<<"$(mk_payload "$FIXROOT/routines/routines.yaml")"
  [ "$status" -eq 0 ]
}

@test "routines-sync-hook: routines.yaml hash does NOT match the snapshot (drift) exits 2" {
  setup_routines_fixture
  printf 'name: foo\ntrigger_id: trig_ABC123\n' >"$FIXROOT/routines/routines.yaml"
  printf 'routines/routines.yaml sha256=stale-hash-from-before-the-edit\n' >"$FIXROOT/.routines-applied"
  run bash "$FIXROOT/scripts/routines-sync-hook.sh" <<<"$(mk_payload "$FIXROOT/routines/routines.yaml")"
  [ "$status" -eq 2 ]
}

@test "routines-sync-hook: drift message names the trigger_id parsed from routines.yaml" {
  setup_routines_fixture
  printf 'name: foo\ntrigger_id: trig_ABC123\n' >"$FIXROOT/routines/routines.yaml"
  printf 'routines/routines.yaml sha256=stale-hash-from-before-the-edit\n' >"$FIXROOT/.routines-applied"
  run bash "$FIXROOT/scripts/routines-sync-hook.sh" <<<"$(mk_payload "$FIXROOT/routines/routines.yaml")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"trig_ABC123"* ]]
}

# --- securitycontext-tests-sync-hook.sh -----------------------------------------

@test "securitycontext-tests-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/securitycontext-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/networkpolicy.bats")"
  [ "$status" -eq 0 ]
}

@test "securitycontext-tests-sync-hook: tests/securitycontext.bats (currently frozen/compliant) exits 0" {
  run bash "$REPO/scripts/securitycontext-tests-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/securitycontext.bats")"
  [ "$status" -eq 0 ]
}

# --- yq-raw-sync-hook.sh ---------------------------------------------------------

@test "yq-raw-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/yq-raw-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "yq-raw-sync-hook: non-bats file exits 0 (filtered out)" {
  run bash "$REPO/scripts/yq-raw-sync-hook.sh" <<<"$(mk_payload "$REPO/ROADMAP.md")"
  [ "$status" -eq 0 ]
}

@test "yq-raw-sync-hook: a real bats file with no bare yq calls exits 0" {
  run bash "$REPO/scripts/yq-raw-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/commit-reminder-hook.bats")"
  [ "$status" -eq 0 ]
}
