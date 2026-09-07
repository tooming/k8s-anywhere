#!/usr/bin/env bats
# Clusterless content test for gitops/apps/demo/configmap.yaml's hardcoded
# git-provenance strings (message/source fields).
#
# Found 2026-09-07 (JANITOR-fallback sweep): this ConfigMap — deployed live as
# part of the lab-demo Application, one of the always-on 6-component core —
# still said "synced by ArgoCD, from GitLab" and `source: "gitlab:..."` after
# both GitLab (ADR-0033) and its Forgejo successor (ADR-0035) were removed
# entirely 2026-09-07, no replacement; ArgoCD has synced this Application
# directly from GitHub (gitops/platform/demo.yaml's own repoURL) the whole
# time. A live ConfigMap asserting the wrong git source is exactly the
# fabricated-state ADR-0004 forbids, and had zero test coverage protecting
# against the drift. This guard makes that recurrence impossible: whichever
# git host gitops/platform/demo.yaml's Application actually points at must be
# the same host this ConfigMap's own strings name.
setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CM="$REPO/gitops/apps/demo/configmap.yaml"
  APP="$REPO/gitops/platform/demo.yaml"
}

@test "gitops/apps/demo/configmap.yaml exists" {
  [ -f "$CM" ]
}

@test "lab-demo-hello ConfigMap's message/source name the same git host as the demo Application's real repoURL" {
  run grep -oE 'repoURL: https://([a-zA-Z0-9.-]+)' "$APP"
  [ "$status" -eq 0 ]
  # "github.com" -> "github": the ConfigMap's own strings name the host, not the FQDN.
  host="$(printf '%s' "$output" | sed -E 's#repoURL: https://##; s#\..*$##')"
  [ -n "$host" ]
  run grep -qi "$host" "$CM"
  [ "$status" -eq 0 ]
}

@test "lab-demo-hello ConfigMap does not name a removed git source (gitlab/forgejo)" {
  run grep -qiE 'gitlab|forgejo' "$CM"
  [ "$status" -ne 0 ]
}
