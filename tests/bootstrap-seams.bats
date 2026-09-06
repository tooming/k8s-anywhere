#!/usr/bin/env bats
# Structural tests for `make up`'s imperative bootstrap seams. All checks are
# clusterless — they assert code structure and Makefile wiring.
#
# gitlab-tls-bootstrap and grafana-gitsync-bootstrap (ADR-0006) — this file's
# original subject — were both removed 2026-09-06 (ADR-0041, observability
# stack removed with no replacement): Grafana's native Git Sync was their only
# consumer.

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

# --- gitlab/.env self-heal (gitlab-up can't run without GITLAB_ROOT_PASSWORD) -
# gitlab/.env is gitignored, so a fresh clone has none and `docker compose up`
# dies on interpolation. gitlab-env-ensure.sh creates it; gitlab-up must call it
# FIRST so the failure mode is impossible by construction.
@test "gitlab-env-ensure.sh exists and is executable" {
  [ -x "$REPO/scripts/gitlab-env-ensure.sh" ]
}

@test "gitlab-up runs gitlab-env-ensure before 'docker compose up'" {
  # The ensure call must precede the compose up line within the gitlab-up recipe.
  run bash -c "awk '/^gitlab-up:/{f=1} f{print} f&&/docker compose up/{exit}' '$REPO/Makefile'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"gitlab-env-ensure.sh"* ]]
  ensure_line=$(printf '%s\n' "$output" | grep -n 'gitlab-env-ensure.sh' | head -1 | cut -d: -f1)
  compose_line=$(printf '%s\n' "$output" | grep -n 'docker compose up' | head -1 | cut -d: -f1)
  [ -n "$ensure_line" ] && [ -n "$compose_line" ] && [ "$ensure_line" -lt "$compose_line" ]
}

@test "gitlab-env-ensure.sh is idempotent (no-op when GITLAB_ROOT_PASSWORD already set)" {
  run grep -c 'already has GITLAB_ROOT_PASSWORD' "$REPO/scripts/gitlab-env-ensure.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# --- gitlab-push must not mirror a stale local main ---------------------------
# A long-lived checkout whose local main lags github/main used to push the stale
# main to the GitLab mirror (or die non-fast-forward once GitLab was ahead) and
# fail `make up` at gitlab-configure. gitlab-push now best-effort fast-forwards
# local main from github first — ancestor-gated (never rewrites local-only
# commits) and ||-true so an offline DR bootstrap still proceeds.
@test "gitlab-push fast-forwards local main from github before mirroring" {
  run grep -n 'merge-base --is-ancestor main github/main' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "gitlab-push main fast-forward is best-effort (offline DR bootstrap survives)" {
  block=$(awk '/^gitlab-push:/,/^$/' "$REPO/Makefile")
  [[ "$block" == *"merge-base --is-ancestor"* ]]
  [[ "$block" == *"|| true"* ]]
}

@test "gitlab-push skips the fast-forward when main is the checked-out branch" {
  block=$(awk '/^gitlab-push:/,/^$/' "$REPO/Makefile")
  [[ "$block" == *'rev-parse --abbrev-ref HEAD'* ]]
  [[ "$block" == *'!= "main"'* ]]
}
