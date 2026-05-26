#!/usr/bin/env bats
# Unit tests for scripts/adr-guard-hook.sh — the PostToolUse hook that
# rejects edits that reintroduce a technology an ADR named *-not-<rejected>*
# has ruled out (e.g. ADR-0002: Garage NOT MinIO).
# No cluster needed: the hook reads a JSON payload from stdin, checks the
# named file, and exits 0 (clean) or 2 (rejection found).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # .yaml in a neutral tmpdir — matches the *.yaml guard but has no rejected term
  CLEAN="$BATS_TEST_TMPDIR/clean.yaml"
  printf 'kind: Deployment\nspec:\n  template:\n    spec:\n      image: nginx:alpine\n' >"$CLEAN"
  # .yaml containing "minio" — rejected by ADR-0002
  DIRTY="$BATS_TEST_TMPDIR/dirty.yaml"
  printf 'kind: Deployment\nspec:\n  template:\n    spec:\n      image: minio/minio:latest\n' >"$DIRTY"
}

mk_payload() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

@test "adr-guard: empty JSON payload exits 0" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "adr-guard: docs/ path is excluded even when file mentions a rejected term" {
  # docs/platform-products.md discusses MinIO by name; the guard must stay silent.
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$REPO/docs/platform-products.md")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: path with no guarded extension or directory exits 0" {
  # A plain file that is neither *.yaml/yml/tf/hcl nor under infra/gitops/scripts.
  PLAIN="$BATS_TEST_TMPDIR/note"
  printf 'minio reference\n' >"$PLAIN"
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$PLAIN")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: clean yaml file exits 0" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$CLEAN")"
  [ "$status" -eq 0 ]
}

@test "adr-guard: yaml containing rejected term exits 2" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
}

@test "adr-guard: rejection message names the rejected term" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"minio"* ]]
}

@test "adr-guard: rejection message names the ADR that enforces the ban" {
  run bash "$REPO/scripts/adr-guard-hook.sh" <<<"$(mk_payload "$DIRTY")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"adr-0002"* ]]
}
