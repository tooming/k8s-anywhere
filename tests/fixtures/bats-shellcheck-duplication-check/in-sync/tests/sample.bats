#!/usr/bin/env bats
# Golden fixture: a normal structural bats test with no direct shellcheck
# invocation. Mentioning "shellcheck" in a comment (like this one, or the line
# below) must NOT trip the check — only an actual `run shellcheck ...` command
# should.
setup() {
  SCRIPT="$(mktemp)"
}
teardown() { rm -f "$SCRIPT"; }

@test "sample.sh exists" {
  [ -f "$SCRIPT" ]
}
