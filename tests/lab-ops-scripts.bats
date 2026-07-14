#!/usr/bin/env bats
# Clusterless structural tests for four operational scripts that had zero bats
# coverage: scripts/dr-verify.sh, scripts/frontdoor-ensure.sh,
# scripts/lab-health-check.sh, scripts/tfstate-bootstrap.sh. All four are wired
# into real `make` targets (dr-verify, frontdoor, health, tfstate-up) and gate
# DR/lab-health workflows (docs/DR.md, ADR-0005) — until now nothing caught an
# accidental structural regression (a deleted budget var, a dropped predicate,
# a Makefile target losing its script invocation). No running cluster required:
# these tests verify declared structure/behaviour only, never execute kubectl/
# docker/k3d/garage against a live target.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DRVERIFY="$REPO/scripts/dr-verify.sh"
  FRONTDOOR="$REPO/scripts/frontdoor-ensure.sh"
  HEALTHCHECK="$REPO/scripts/lab-health-check.sh"
  TFSTATE="$REPO/scripts/tfstate-bootstrap.sh"
  MAKEFILE="$REPO/Makefile"
}

# --- scripts/dr-verify.sh -----------------------------------------------------
@test "dr-verify.sh exists" {
  [ -f "$DRVERIFY" ]
}

@test "dr-verify.sh is executable" {
  [ -x "$DRVERIFY" ]
}

@test "dr-verify.sh defines a budget var for every real check (nodes/argo/vault/eso/garage/mimir/grafana)" {
  for v in T_NODES T_ARGO T_VAULT T_ESO T_GARAGE T_MIMIR T_GRAFANA; do
    run grep -q "$v=" "$DRVERIFY"
    [ "$status" -eq 0 ]
  done
}

@test "dr-verify.sh checks ArgoCD Applications are Synced and Healthy" {
  run grep -q 'sync.status=="Synced"' "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh checks Vault is initialized and unsealed" {
  run grep -q "initialized" "$DRVERIFY"
  [ "$status" -eq 0 ]
  run grep -q "sealed" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh checks ExternalSecrets report Ready" {
  run grep -q "externalsecrets.external-secrets.io" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh checks Garage buckets exist" {
  run grep -q "GARAGE_BUCKETS=" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh queries Mimir with the lab tenant header (ADR-0004: real data, no fabrication)" {
  run grep -q "X-Scope-OrgID: lab" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh checks Grafana /api/health" {
  run grep -q "/api/health" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

@test "dr-verify.sh exits 0 on pass and 1 on fail" {
  run grep -q "exit 0" "$DRVERIFY"
  [ "$status" -eq 0 ]
  run grep -q "exit 1" "$DRVERIFY"
  [ "$status" -eq 0 ]
}

# --- scripts/frontdoor-ensure.sh ---------------------------------------------
@test "frontdoor-ensure.sh exists" {
  [ -f "$FRONTDOOR" ]
}

@test "frontdoor-ensure.sh is executable" {
  [ -x "$FRONTDOOR" ]
}

@test "frontdoor-ensure.sh auto-picks the running cluster when none is passed" {
  run grep -q "k3d cluster list" "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "frontdoor-ensure.sh prefers the blue (k8s-lab) cluster when both are running" {
  run grep -q "k8s-lab" "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "frontdoor-ensure.sh delegates to bluegreen-frontdoor.sh" {
  run grep -q "bluegreen-frontdoor.sh" "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

@test "frontdoor-ensure.sh fails loudly when it can't auto-pick a cluster" {
  run grep -q "can't auto-pick a cluster" "$FRONTDOOR"
  [ "$status" -eq 0 ]
}

# --- scripts/lab-health-check.sh ---------------------------------------------
@test "lab-health-check.sh exists" {
  [ -f "$HEALTHCHECK" ]
}

@test "lab-health-check.sh is executable" {
  [ -x "$HEALTHCHECK" ]
}

@test "lab-health-check.sh has a configurable poll budget (HEALTH_WAIT)" {
  run grep -q 'WAIT="${HEALTH_WAIT:-90}"' "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

@test "lab-health-check.sh excludes on-demand namespaces from the always-on gate" {
  run grep -q "LAB_ONDEMAND_NS" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

@test "lab-health-check.sh ignores Job-owned pods (ephemeral by design)" {
  run grep -q '"Job"' "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

@test "lab-health-check.sh probes the Envoy front door over HTTP, not just pod readiness" {
  run grep -q "UI_PROBES" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

@test "lab-health-check.sh exits 2 when the cluster is unreachable, distinct from 1 (unhealthy)" {
  run grep -q "cluster unreachable" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
  run grep -q "exit 2" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

# --- scripts/tfstate-bootstrap.sh ---------------------------------------------
@test "tfstate-bootstrap.sh exists" {
  [ -f "$TFSTATE" ]
}

@test "tfstate-bootstrap.sh is executable" {
  [ -x "$TFSTATE" ]
}

@test "tfstate-bootstrap.sh requires AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY" {
  run grep -q "AWS_ACCESS_KEY_ID" "$TFSTATE"
  [ "$status" -eq 0 ]
  run grep -q "AWS_SECRET_ACCESS_KEY" "$TFSTATE"
  [ "$status" -eq 0 ]
}

@test "tfstate-bootstrap.sh is idempotent on layout assignment (checks NO ROLE first)" {
  run grep -q "NO ROLE" "$TFSTATE"
  [ "$status" -eq 0 ]
}

@test "tfstate-bootstrap.sh is idempotent on key import (checks key info first)" {
  run grep -q "key info tfstate" "$TFSTATE"
  [ "$status" -eq 0 ]
}

@test "tfstate-bootstrap.sh creates the tfstate bucket with read+write grants" {
  run grep -q "bucket create tfstate" "$TFSTATE"
  [ "$status" -eq 0 ]
  run grep -q "bucket allow --read --write tfstate" "$TFSTATE"
  [ "$status" -eq 0 ]
}

# --- Makefile wiring ----------------------------------------------------------
@test "Makefile dr-verify target invokes dr-verify.sh" {
  run grep -A1 '^dr-verify:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dr-verify.sh"* ]]
}

@test "Makefile frontdoor target invokes frontdoor-ensure.sh" {
  run grep -A1 '^frontdoor:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"frontdoor-ensure.sh"* ]]
}

@test "Makefile health target invokes lab-health-check.sh" {
  run grep -A1 '^health:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lab-health-check.sh"* ]]
}

@test "Makefile up target also invokes lab-health-check.sh (post-bootstrap gate)" {
  run grep -q "lab-health-check.sh" "$MAKEFILE"
  [ "$status" -eq 0 ]
}

@test "Makefile tfstate-up target invokes tfstate-bootstrap.sh" {
  run grep -A4 '^tfstate-up:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tfstate-bootstrap.sh"* ]]
}

@test "Makefile declares .PHONY for dr-verify, frontdoor, health, tfstate-up" {
  for t in dr-verify frontdoor health tfstate-up; do
    run grep -q "\.PHONY: $t\$" "$MAKEFILE"
    [ "$status" -eq 0 ]
  done
}
