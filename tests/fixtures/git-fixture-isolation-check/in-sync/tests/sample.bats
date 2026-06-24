#!/usr/bin/env bats
# Golden fixture: builds a git fixture AND unsets GIT_* in setup(), so it survives
# a hook-invoked `make ci`. Mentioning git init in a comment must NOT trip the check.
setup() {
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_NAMESPACE
  WORK="$(mktemp -d)"
}
teardown() { rm -rf "$WORK"; }

@test "builds an isolated git fixture" {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
}
