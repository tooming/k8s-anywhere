#!/usr/bin/env bats
# Golden fixture: greps a file's content for a "git clone"-shaped string — never
# runs git itself, so it needs no GIT_DIR isolation and no unset in setup(). The
# check must NOT flag this as a leaky fixture (found live 2026-08-17: an early
# version of the check couldn't tell "runs git clone" apart from "greps for the
# string git clone" and flagged tests/forgejo-ci.bats's real-world equivalent,
# which asserts a workflow YAML file's *text content* contains that shell command).
setup() {
  SAMPLE_FILE="$(mktemp)"
  # Built from parts so this setup() line itself never spells out "git clone" —
  # keeps this fixture file honest about only the @test line below doing the grep.
  printf 'some-command: %s %s --no-checkout\n' "git" "clone" > "$SAMPLE_FILE"
}
teardown() { rm -f "$SAMPLE_FILE"; }

@test "asserts a file's content mentions a git-clone command as text, without running git" {
  grep -q 'git clone --no-checkout' "$SAMPLE_FILE"
}
