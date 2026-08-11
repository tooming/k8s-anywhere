#!/usr/bin/env bats
# Coverage for scripts/probe-timeout-sync-hook.sh — its own file per the
# tests/hook-scripts-coverage.bats convention (that monolith is now FROZEN; new
# hook-script coverage goes in its own tests/hook-scripts-<scope>.bats file).
# Mirrors tests/hook-scripts-coverage.bats' own mimir-readonly-root-sync-hook
# pattern: feed a JSON payload on stdin, assert the exit code (0 = silent,
# 2 = nudge shown).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "probe-timeout-sync-hook: empty payload exits 0" {
  run bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-sync-hook: a file outside gitops/ and infra/ exits 0 (filtered out)" {
  run bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/README.md")"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-sync-hook: a tests/fixtures/ path exits 0 (filtered out)" {
  run bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/tests/fixtures/probe-timeout-check/drift-unset/gitops/bad.yaml")"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-sync-hook: a non-YAML file under gitops/ exits 0 (filtered out)" {
  run bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/README.md")"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-sync-hook: a real, compliant gitops manifest exits 0" {
  run bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"$(mk_payload "$REPO/gitops/data/valkey/statefulset.yaml")"
  [ "$status" -eq 0 ]
}

@test "probe-timeout-sync-hook: a scratch gitops-tree copy with a too-tight probe exits 2 (nudge)" {
  # No git fixture needed here (probe-timeout-check.sh only walks YAML under
  # PROBETIMEOUTCHECK_ROOT, no git operations) — a plain tmp dir is enough, and
  # sidesteps the GIT_DIR-leak footgun scripts/git-fixture-isolation-check.sh
  # guards against.
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/gitops"
  cp "$REPO/tests/fixtures/probe-timeout-check/drift-tight/gitops/bad.yaml" "$tmp/gitops/bad.yaml"
  run env PROBETIMEOUTCHECK_ROOT="$tmp" PROBETIMEOUTCHECK_REQUIRED="" \
          bash "$REPO/scripts/probe-timeout-sync-hook.sh" <<<"$(mk_payload "$tmp/gitops/bad.yaml")"
  rm -rf "$tmp"
  [ "$status" -eq 2 ]
  [[ "$output" == *"timeoutSeconds"* ]]
}
