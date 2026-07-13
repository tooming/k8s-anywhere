#!/usr/bin/env bats
# Unit tests for scripts/merge-ci-gate-hook.sh — the PostToolUse hook that flags a
# `gh pr merge` Bash command run against a PR with a non-passing check (born from the
# 2026-07-13 incident: an agent self-merged over a known-red required check; see PR
# #375). Stubs `gh` on PATH so no network/real GitHub access is needed.
# No cluster needed: the hook reads a JSON payload from stdin and exits 0 (clean) or
# 2 (flagged).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  STUBDIR="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUBDIR"
  PATH="$STUBDIR:$PATH"
}

mk_payload() { printf '{"tool_input":{"command":"%s"}}' "$1"; }

stub_gh_green() {
  cat >"$STUBDIR/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
  echo "lint	pass	5s	https://example.com"
  exit 0
fi
exit 1
EOF
  chmod +x "$STUBDIR/gh"
}

stub_gh_red() {
  cat >"$STUBDIR/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
  echo "drift	fail	5s	https://example.com"
  exit 8
fi
exit 1
EOF
  chmod +x "$STUBDIR/gh"
}

stub_gh_auth_error() {
  # Simulates a real (but unauthenticated) gh — the exact CI runner scenario that
  # broke the original exit-code-based version of this hook: GitHub-hosted runners
  # ship a real `gh` on PATH, so "no gh available" can't be tested by just clearing
  # PATH — it must be tested by making gh fail for a *non-CI-related* reason and
  # confirming the hook still doesn't flag it (see merge-ci-gate-no-gh-in-minimal-path
  # test for the true "gh absent" case).
  cat >"$STUBDIR/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
  echo "To use GitHub CLI in a GitHub Actions workflow, set the GH_TOKEN environment variable." >&2
  exit 4
fi
exit 1
EOF
  chmod +x "$STUBDIR/gh"
}

# A PATH containing only symlinks to the real coreutils this script needs (grep, jq),
# resolved via `command -v` *before* PATH is restricted — guaranteed to exclude `gh`
# regardless of whether the underlying environment (e.g. a GitHub-hosted runner) has
# a real gh installed somewhere. Plain `PATH="/usr/bin:/bin"` is NOT sufficient for
# this — GitHub Actions runners ship gh at exactly that kind of standard location.
minimal_path_without_gh() {
  MINPATH="$BATS_TEST_TMPDIR/minpath"
  mkdir -p "$MINPATH"
  # bash itself is required too — `run bash "$REPO/..."` resolves `bash` via PATH
  # like any other command, so a PATH without it would fail with "bash: not found"
  # rather than actually exercising the script's own gh-detection logic.
  for bin in bash cat grep head jq; do
    tool="$(command -v "$bin")"
    ln -sf "$tool" "$MINPATH/$bin"
  done
  PATH="$MINPATH"
}

@test "merge-ci-gate: empty JSON payload exits 0" {
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"{}"
  [ "$status" -eq 0 ]
}

@test "merge-ci-gate: non-merge command exits 0 without invoking gh" {
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr create --title foo")"
  [ "$status" -eq 0 ]
}

@test "merge-ci-gate: gh not on PATH exits 0 (never false-positive on missing tooling)" {
  minimal_path_without_gh
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr merge 123 --squash")"
  [ "$status" -eq 0 ]
}

@test "merge-ci-gate: gh present but erroring for a non-CI reason (e.g. no GH_TOKEN) exits 0" {
  # The exact bug this test guards against: an earlier version of this hook trusted
  # gh's exit code alone, so a real-but-unauthenticated gh (present on every
  # GitHub-hosted runner) made every merge-CI-gate test fail in CI, since gh pr
  # checks exits non-zero on auth failure just as it does on a real failing check.
  stub_gh_auth_error
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr merge 123 --squash")"
  [ "$status" -eq 0 ]
}

@test "merge-ci-gate: gh pr merge against a fully green PR exits 0" {
  stub_gh_green
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr merge 123 --squash --delete-branch")"
  [ "$status" -eq 0 ]
}

@test "merge-ci-gate: gh pr merge against a red PR exits 2" {
  stub_gh_red
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr merge 375 --squash")"
  [ "$status" -eq 2 ]
}

@test "merge-ci-gate: red-PR message names the PR number and cites WAYS-OF-WORKING.md" {
  stub_gh_red
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "gh pr merge 375 --squash")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"375"* ]]
  [[ "$output" == *"WAYS-OF-WORKING.md"* ]]
}

@test "merge-ci-gate: extracts the PR number correctly out of a longer command line" {
  stub_gh_red
  run bash "$REPO/scripts/merge-ci-gate-hook.sh" <<<"$(mk_payload "cd /repo && gh pr merge 42 --squash --delete-branch && echo done")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"drift"* ]]
}
