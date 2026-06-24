#!/usr/bin/env bats
# Drift fixture: builds a git fixture but never unsets GIT_*, so it breaks the
# instant `make ci` runs from a hook. The check must flag it.
setup() {
  WORK="$(mktemp -d)"
}
teardown() { rm -rf "$WORK"; }

@test "builds a leaky git fixture" {
  git init -q --bare "$WORK/remote.git"
  git clone -q "$WORK/remote.git" "$WORK/clone"
}
