#!/usr/bin/env bats
# Guard for .githooks/pre-push ref selection: every check must key off the refs
# actually being pushed (stdin), never the checked-out branch. Regression: `make
# gitlab-push` (inside `make up`) pushes MAIN while a feature branch is checked
# out — the old hook compared HEAD to main and blocked the bootstrap.
# Hermetic: scratch git repos, `make` stubbed on PATH, gh disabled via GH_BIN.

setup() {
  # git exports these into hooks; make ci runs from pre-push, so without the
  # unset the fixture's git commands would hit the REAL repo
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_NAMESPACE

  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  HOOK="$REPO/.githooks/pre-push"
  WORK="$(mktemp -d)"

  # make stub so the allow-path lint gate is a fast no-op; logs its args so tests
  # can assert which target the hook actually invokes (see the lint-not-ci test).
  mkdir -p "$WORK/bin"
  printf '#!/usr/bin/env bash\necho "make $*" >> "%s/make-calls.log"\nexit 0\n' "$WORK" > "$WORK/bin/make"
  chmod +x "$WORK/bin/make"
  export PATH="$WORK/bin:$PATH"
  export GH_BIN="$WORK/no-such-gh"   # merged-PR check degrades to allow

  # origin with main at 2 commits; clone whose main is 1 behind
  git init -q --bare "$WORK/origin.git"
  git init -q -b main "$WORK/clone"
  cd "$WORK/clone"
  git config user.email t@t && git config user.name t
  echo one > f && git add f && git commit -qm c1
  git checkout -qb feature            # feature forks at c1
  git checkout -q main
  echo two >> f && git commit -qam c2
  git remote add origin "$WORK/origin.git"
  git push -q origin main
}
teardown() { rm -rf "$WORK"; }

sha() { git rev-parse "$1"; }
Z=0000000000000000000000000000000000000000

@test "pushing main from a feature-branch checkout is allowed (make up regression)" {
  git checkout -q feature             # HEAD behind main — must not matter
  run bash -c "echo 'refs/heads/main $(sha main) refs/heads/main $Z' | bash '$HOOK' origin"
  [ "$status" -eq 0 ]
}

@test "pushing a feature branch behind main is blocked" {
  run bash -c "echo 'refs/heads/feature $(sha feature) refs/heads/feature $Z' | bash '$HOOK' origin"
  [ "$status" -eq 1 ]
  [[ "$output" == *"behind main"* ]]
}

@test "block message names the pushed branch" {
  run bash -c "echo 'refs/heads/feature $(sha feature) refs/heads/feature $Z' | bash '$HOOK' origin"
  [[ "$output" == *"Branch feature is"* ]]
}

@test "pushing a rebased (up-to-date) feature branch is allowed" {
  git checkout -q feature
  git rebase -q main
  run bash -c "echo 'refs/heads/feature $(sha feature) refs/heads/feature $Z' | bash '$HOOK' origin"
  [ "$status" -eq 0 ]
}

@test "deleting a stale feature branch is allowed" {
  run bash -c "echo '(delete) $Z refs/heads/feature $(sha feature)' | bash '$HOOK' origin"
  [ "$status" -eq 0 ]
}

@test "hook does not consult the checked-out branch for the behind-main check" {
  run grep -n 'rev-parse --abbrev-ref HEAD' "$HOOK"
  [ "$status" -ne 0 ]
}

@test "pre-push hook runs the fast lint gate locally, not the full make ci (GitHub Actions covers the rest)" {
  git checkout -q feature
  run bash -c "echo 'refs/heads/main $(sha main) refs/heads/main $Z' | bash '$HOOK' origin"
  [ "$status" -eq 0 ]
  run cat "$WORK/make-calls.log"
  [[ "$output" == *" lint"* ]]
  [[ "$output" != *" ci"* ]]
}
