#!/usr/bin/env bats
# Coverage for scripts/context-doc-version-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "context-doc-version-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: the real, currently-clean context.md exits 0" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/decisions/context.md")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: the real, currently-clean dependency-tree.md exits 0" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/docs/dependency-tree.md")"
  [ "$status" -eq 0 ]
}

@test "context-doc-version-sync-hook: a gitops manifest edit exits 0 when still in sync" {
  run bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/platform/argocd-extras.yaml")"
  [ "$status" -eq 0 ]
}

# The KRO/ACK s3-controller check_one calls this test used to exercise (and, before
# them, the Grafana/Pyroscope calls) were all removed as their components were removed
# (ADR-0041 2026-09-06, ADR-0038 2026-09-07) — context.md itself tracks zero prose
# version citations again, so a context.md edit still can't produce a "drift" exit 2
# no matter how stale-looking its content is.
@test "context-doc-version-sync-hook: a context.md edit exits 0 (context.md itself currently tracks zero citations)" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/docs/decisions" "$BATS_TEST_TMPDIR/fixture/gitops/platform"
  cat > "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md" <<'MD'
Some stale-looking prose that no check_one call parses.
MD
  run env CONTEXTDOCCHECK_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/docs/decisions/context.md")"
  [ "$status" -eq 0 ]
}

# dependency-tree.md's cert-manager citation (added 2026-09-14) is a real, live
# check_one call — a stale dependency-tree.md now genuinely produces a "drift"
# exit 2, unlike the context.md case above.
@test "context-doc-version-sync-hook: a stale dependency-tree.md edit exits 2 (real drift, cert-manager citation)" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/docs" "$BATS_TEST_TMPDIR/fixture/gitops/platform"
  cat > "$BATS_TEST_TMPDIR/fixture/docs/dependency-tree.md" <<'MD'
cert-manager (chart `cert-manager` v1.21.1 from https://charts.jetstack.io)
MD
  cat > "$BATS_TEST_TMPDIR/fixture/gitops/platform/cert-manager.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
spec:
  source:
    repoURL: https://charts.jetstack.io
    chart: cert-manager
    targetRevision: 1.21.2
YAML
  run env CONTEXTDOCCHECK_ROOT="$BATS_TEST_TMPDIR/fixture" \
      bash "$REPO/scripts/context-doc-version-sync-hook.sh" \
      <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/docs/dependency-tree.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"dependency-tree.md"* ]]
}
