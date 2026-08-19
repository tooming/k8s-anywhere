#!/usr/bin/env bats
# Recurrence guard for the Harbor migration (RFC #297 / ADR-0024,
# `auto/harbor-artifactory-decommission`): the legacy JFrog registry's
# manifests, Make targets, and appset entry were fully removed once the
# capstone pipeline cut over to Harbor. This asserts none of that ever comes
# back — a mechanical guard, not a one-time cleanup, per CLAUDE.md's
# bugfix-prevents-recurrence rule.
#
# Scope is deliberately gitops/ + Makefile only (not docs/decisions/ or
# docs/done/), matching the ROADMAP item's own guard spec: the legacy
# registry's name is expected to persist in ADR-0011/0024's historical
# decision record and in docs/done/'s permanent Done log — that is real
# history, not drift.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "no legacy-registry ArgoCD Application/route/networkpolicy manifest remains under gitops/" {
  run grep -ril 'artifactory' "$REPO/gitops/"
  [ "$status" -ne 0 ]
}

@test "no legacy-registry make target remains in the Makefile" {
  run grep -i 'artifactory' "$REPO/Makefile"
  [ "$status" -ne 0 ]
}

@test "the legacy registry's gitops/ directory tree is gone" {
  [ ! -d "$REPO/gitops/artifactory" ]
}

@test "the legacy registry's platform Applications are gone" {
  [ ! -f "$REPO/gitops/platform/artifactory.yaml" ]
  [ ! -f "$REPO/gitops/platform/artifactory-extras.yaml" ]
}

@test "the legacy registry's orphaned ExternalSecret is gone" {
  [ ! -f "$REPO/gitops/secrets/artifactory-registry-externalsecret.yaml" ]
}

@test "networkpolicy-appset.yaml no longer lists a legacy-registry entry" {
  run grep -i 'artifactory' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -ne 0 ]
}

@test "the architect routine's weekly upstream-release check tracks Harbor, not the decommissioned Artifactory (ADR-0024, 2026-08-19)" {
  # routines/architect.prompt.md STEP 1 hardcodes a fixed list of repos to
  # check for new releases each week. It still named jfrog/charts
  # (Artifactory) months after ADR-0024 fully decommissioned it in favor of
  # Harbor — the architect routine was checking a technology this lab no
  # longer runs at all, instead of the one it does. Unlike gitops/ + Makefile
  # above, this file is live operating instruction (not historical decision
  # record), so it's held to the same "no legacy-registry reference" bar.
  prompt="$REPO/routines/architect.prompt.md"
  run grep -qi 'jfrog\|artifactory' "$prompt"
  [ "$status" -ne 0 ]
  run grep -qF 'goharbor/harbor-helm' "$prompt"
  [ "$status" -eq 0 ]
}
