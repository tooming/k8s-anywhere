#!/usr/bin/env bats
# Structural tests for the two imperative bootstrap seams wired into `make up`
# (ADR-0006): gitlab-tls-bootstrap and grafana-gitsync-bootstrap.
# All checks are clusterless — they assert code structure and Makefile wiring.

setup() { REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

# --- scripts present and executable ------------------------------------------
@test "gitlab-tls-bootstrap.sh exists and is executable" {
  [ -x "$REPO/scripts/gitlab-tls-bootstrap.sh" ]
}

@test "grafana-gitsync-bootstrap.sh exists and is executable" {
  [ -x "$REPO/scripts/grafana-gitsync-bootstrap.sh" ]
}

# --- make up wires both bootstraps -------------------------------------------
@test "make up calls gitlab-tls-bootstrap" {
  run grep -n 'gitlab-tls-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  # Must appear in the 'up' recipe (not only as a standalone target header)
  [[ "$output" == *"MAKE) gitlab-tls-bootstrap"* ]]
}

@test "make up calls grafana-gitsync-bootstrap" {
  run grep -n 'grafana-gitsync-bootstrap' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MAKE) grafana-gitsync-bootstrap"* ]]
}

@test "make up calls gitlab-tls-bootstrap before grafana-gitsync-bootstrap" {
  tls_line=$(grep -n 'MAKE) gitlab-tls-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  gs_line=$(grep -n 'MAKE) grafana-gitsync-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  [ -n "$tls_line" ] && [ -n "$gs_line" ]
  [ "$tls_line" -lt "$gs_line" ]
}

@test "make up calls gitlab-tls-bootstrap after vault-bootstrap" {
  vault_line=$(grep -n 'MAKE) vault-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  tls_line=$(grep -n 'MAKE) gitlab-tls-bootstrap' "$REPO/Makefile" | head -1 | cut -d: -f1)
  [ -n "$vault_line" ] && [ -n "$tls_line" ]
  [ "$vault_line" -lt "$tls_line" ]
}

# --- ADR-0006 prose does not re-drift once both bootstraps are wired ---------
# ADR-0006 previously claimed "(Follow-up: wire both bootstraps into make up/DR.)"
# after that follow-up was already done, going stale until caught by a planner
# gap-analysis run. Both bootstraps are proven wired above (the two "make up
# calls ..." tests); this asserts the ADR text doesn't claim otherwise again.
@test "ADR-0006 does not carry a stale 'Follow-up' note about the bootstrap wiring" {
  run grep -c 'Follow-up: wire both bootstraps into' "$REPO/docs/decisions/adr-0006-grafana-native-git-sync.md"
  [ "$status" -eq 1 ]
  [ "$output" -eq 0 ]
}

# --- gitlab-tls-bootstrap has Grafana restart logic --------------------------
@test "gitlab-tls-bootstrap.sh rolls Grafana deployment when it is already running" {
  run grep -c 'rollout restart deployment/grafana' "$REPO/scripts/gitlab-tls-bootstrap.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# --- grafana-gitsync-bootstrap has a health wait loop ------------------------
@test "grafana-gitsync-bootstrap.sh waits for Grafana /api/health before calling the API" {
  run grep -c '/api/health' "$REPO/scripts/grafana-gitsync-bootstrap.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "grafana-gitsync-bootstrap.sh defaults GRAFANA_URL to the stable front door :8000, not a per-cluster Envoy port" {
  run grep -oE 'GRAFANA_URL="\$\{GRAFANA_URL:-[^}]+\}"' "$REPO/scripts/grafana-gitsync-bootstrap.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *":8080"* ]]
  [[ "$output" == *":8000"* ]]
}

# --- DR.md documents both new steps ------------------------------------------
@test "DR.md documents gitlab-tls-bootstrap in the bootstrap order table" {
  run grep -c 'gitlab-tls-bootstrap' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "DR.md documents grafana-gitsync-bootstrap in the bootstrap order table" {
  run grep -c 'grafana-gitsync-bootstrap' "$REPO/docs/DR.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
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

# --- grafana-gitsync wait must clear the cold-start dashboard download --------
# download-dashboards curls each community gnetId dashboard from grafana.com at up
# to --max-time 60s. If GRAFANA_WAIT is shorter than that budget, `make up` fails
# its LAST step on a fresh lab. Keep the wait >= (#gnetId x 60) + startup headroom.
@test "grafana-gitsync GRAFANA_WAIT covers the community-dashboard download budget" {
  ndash=$(grep -c 'gnetId:' "$REPO/gitops/platform/observability-grafana.yaml")
  wait=$(grep -oE 'GRAFANA_WAIT:-[0-9]+' "$REPO/scripts/grafana-gitsync-bootstrap.sh" | grep -oE '[0-9]+' | head -1)
  [ -n "$wait" ]
  budget=$(( ndash * 60 + 120 ))
  [ "$wait" -ge "$budget" ]
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
