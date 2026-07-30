#!/usr/bin/env bats
# Coverage for scripts/kustomize-orphan-sync-hook.sh — its own file per the
# hook-scripts-coverage-tests-check convention (tests/hook-scripts-coverage.bats
# is frozen; new hook-script coverage goes in tests/hook-scripts-<scope>.bats).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "kustomize-orphan-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-sync-hook: unrelated file exits 0 (filtered out)" {
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-sync-hook: a non-yaml file under gitops/ exits 0 (filtered out)" {
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/README.md")"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-sync-hook: a directory with no kustomization.yaml exits 0" {
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/network/policies/default-deny.yaml")"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-sync-hook: a real, currently-clean kustomization directory exits 0" {
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" \
    <<<"$(mk_payload "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml")"
  [ "$status" -eq 0 ]
}

@test "kustomize-orphan-sync-hook: an orphaned file next to kustomization.yaml exits 2" {
  mkdir -p "$BATS_TEST_TMPDIR/fixture/gitops/foo"
  cat > "$BATS_TEST_TMPDIR/fixture/gitops/foo/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - live.yaml
YAML
  echo "kind: NetworkPolicy" > "$BATS_TEST_TMPDIR/fixture/gitops/foo/live.yaml"
  echo "kind: NetworkPolicy" > "$BATS_TEST_TMPDIR/fixture/gitops/foo/dead.yaml"
  run bash "$REPO/scripts/kustomize-orphan-sync-hook.sh" \
    <<<"$(mk_payload "$BATS_TEST_TMPDIR/fixture/gitops/foo/dead.yaml")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"isn't referenced by kustomization.yaml"* ]]
}
