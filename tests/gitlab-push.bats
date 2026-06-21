#!/usr/bin/env bats
# Clusterless structural guards for `make gitlab-push`. A from-scratch `make up`
# pushes the gitops repo to a freshly-booted in-cluster GitLab, which exposes two
# auth footguns that BOTH surface as "HTTP Basic: Access denied" and must stay
# guarded (see the comment on the gitlab-push target in the Makefile):
#   1. PAT activation race — the git-over-HTTP path (workhorse/gitlab-shell) lags
#      the Rails API in accepting a brand-new token, so the push must wait until
#      git-receive-pack accepts it before pushing.
#   2. Stale cached credential — a host credential helper (e.g. osxkeychain)
#      persists across GitLab rebuilds and serves a dead token from a previous
#      instance, so the push must isolate the helper list to the repo helper.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "Makefile has a gitlab-push target" {
  run grep -E '^gitlab-push:' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "gitlab-push waits for the PAT via a git-receive-pack probe (activation-race guard)" {
  run grep -F 'info/refs?service=git-receive-pack' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "gitlab-push isolates the credential helper so a stale cached token can't win (keychain guard)" {
  # `-c credential.helper=` resets inherited helpers (osxkeychain, etc.) so only
  # the repo helper that reads gitlab/.gitlab-token is consulted for the push.
  run grep -F 'credential.helper=' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "gitlab-push resolves the token through scripts/gitlab-credential-helper.sh" {
  run grep -F 'scripts/gitlab-credential-helper.sh' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}
