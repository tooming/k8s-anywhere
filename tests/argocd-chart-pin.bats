#!/usr/bin/env bats
# RFC #785 recurrence guard: infra/modules/argocd's chart_version pin and its
# required global.networkPolicy.create: false companion override must move
# together. The chart's 9.x -> 10.x line flips that key's upstream default
# from false to true; this repo already hand-manages its own default-deny +
# allow-list NetworkPolicy set for the argocd namespace via GitOps
# (gitops/argocd/networkpolicy/, ADR-0016 pattern), so a future chart bump
# that drops the override would silently let the chart start templating a
# second, uncoordinated NetworkPolicy set alongside it.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VARS="$REPO/infra/modules/argocd/variables.tf"
  VALS="$REPO/infra/modules/argocd/values.yaml"
  LOCAL_TG="$REPO/infra/live/local/argocd/terragrunt.hcl"
  ORACLE_TG="$REPO/infra/live/oracle/argocd/terragrunt.hcl"
  load lib/yq
}

@test "argocd chart_version default is pinned to 10.5.0 (RFC #785)" {
  run sed -n '/^variable "chart_version" {/,/^}/p' "$VARS"
  [ "$status" -eq 0 ]
  [[ "$output" == *'default     = "10.5.0"'* ]]
}

@test "argocd chart_version default is not the stale 10.4.0 or 10.3.3 pin" {
  run sed -n '/^variable "chart_version" {/,/^}/p' "$VARS"
  [ "$status" -eq 0 ]
  [[ "$output" != *'default     = "10.4.0"'* ]]
  [[ "$output" != *'default     = "10.3.3"'* ]]
}

@test "argocd terragrunt.hcl inputs don't silently override the module default" {
  grep -q 'chart_version = "10.5.0"' "$LOCAL_TG"
  grep -q 'chart_version = "10.5.0"' "$ORACLE_TG"
}

@test "argocd values.yaml sets global.networkPolicy.create: false (RFC #785)" {
  [ "$(yqs '.global.networkPolicy.create' "$VALS")" = "false" ]
}
