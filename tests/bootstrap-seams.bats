#!/usr/bin/env bats
# Structural tests for `make up`'s imperative bootstrap seams. All checks are
# clusterless — they assert code structure and Makefile wiring.
#
# gitlab-tls-bootstrap and grafana-gitsync-bootstrap (ADR-0006) — this file's
# original subject — were both removed 2026-09-06 (ADR-0041, observability
# stack removed with no replacement): Grafana's native Git Sync was their only
# consumer. This file's other original subject, GitLab itself (gitlab-up,
# gitlab-push, gitlab-env-ensure.sh and friends), was removed entirely
# 2026-09-07, no replacement — the repo now lives only on its public GitHub
# remote; that section was removed in the same change.

setup() { REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

@test "gitlab-tls-bootstrap.sh and grafana-gitsync-bootstrap.sh no longer exist (ADR-0041)" {
  [ ! -f "$REPO/scripts/gitlab-tls-bootstrap.sh" ]
  [ ! -f "$REPO/scripts/grafana-gitsync-bootstrap.sh" ]
}

@test "make up no longer calls gitlab-tls-bootstrap or grafana-gitsync-bootstrap (ADR-0041)" {
  run grep -c 'MAKE) gitlab-tls-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 1 ]
  run grep -c 'MAKE) grafana-gitsync-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 1 ]
}

# --- every make up sub-target is documented in DR.md's order table -----------
# DR.md's table previously omitted 4 of 15 real `make up` steps (tfstate-up,
# coredns-host-alias, cosign-bootstrap, frontdoor) — caught by a doc-drift sweep,
# not by any prior test. This generically re-derives the full step list from the
# Makefile's own `up:` recipe so a future step added to `up:` without a matching
# DR.md row fails CI, instead of relying on one hardcoded assertion per step.
@test "every make up sub-target appears in DR.md's bootstrap order table" {
  targets=$(sed -n '/^up:/,/^\.PHONY: down/p' "$REPO/Makefile" | grep -oE '\$\(MAKE\) [a-z0-9-]+' | awk '{print $2}')
  [ -n "$targets" ]
  while IFS= read -r target; do
    run grep -q "\`$target\`" "$REPO/docs/DR.md"
    [ "$status" -eq 0 ]
  done <<< "$targets"
}

@test "no gitlab-* Makefile targets remain (GitLab removed entirely 2026-09-07, no replacement)" {
  run grep -E '^gitlab-[a-z-]+:' "$REPO/Makefile"
  [ "$status" -ne 0 ]
}

@test "no gitlab-*.sh scripts remain (GitLab removed entirely 2026-09-07, no replacement)" {
  run bash -c "ls '$REPO'/scripts/gitlab-*.sh 2>/dev/null"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}
