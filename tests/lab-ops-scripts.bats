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
  BUDGET="$REPO/scripts/ondemand-budget-check.sh"
  DATASTORE="$REPO/scripts/k3s-datastore-health-check.sh"
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

@test "lab-health-check.sh probes the Traefik front door over HTTP, not just pod readiness" {
  run grep -q "UI_PROBES" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

@test "lab-health-check.sh default UI_PROBES uses the stable front door :8000, not a per-cluster Traefik port" {
  # :8080/:8082 are blue/green's own direct ports — they disappear when that
  # cluster is torn down after a blue/green cutover (docs/DR.md), so a
  # hardcoded per-cluster port here would make `make health` silently probe a
  # since-removed backend post-cutover. Only the stable :8000 front door
  # (scripts/bluegreen-frontdoor.sh) survives a cutover.
  run grep -oE 'UI_PROBES="\$\{LAB_UI_PROBES:-[^}]+\}"' "$HEALTHCHECK"
  [ "$status" -eq 0 ]
  [[ "$output" != *":8080"* ]]
  [[ "$output" != *":8082"* ]]
  [[ "$output" == *":8000"* ]]
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

# --- creds/argocd-ui print the stable front door, not a per-cluster Traefik port --
# `make up`'s own completion banner already advertises :8000 as the canonical entry
# point (docs/DR.md, scripts/bluegreen-frontdoor.sh); `creds`/`argocd-ui` printing
# :8080 instead was a real inconsistency a fresh-bootstrap user would hit immediately,
# and a real breakage post-blue/green-cutover once :8080 stops existing.
@test "Makefile creds target prints the front door :8000 for ArgoCD/Grafana/Vault/RabbitMQ, not :8080" {
  run grep -A6 '^creds:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"argocd.127.0.0.1.nip.io:8000"* ]]
  [[ "$output" == *"http://localhost:8000\""* ]]
  [[ "$output" == *"vault.127.0.0.1.nip.io:8000"* ]]
  [[ "$output" == *"rabbitmq.127.0.0.1.nip.io:8000"* ]]
  [[ "$output" != *":8080"* ]]
}

@test "Makefile argocd-ui target's comment offers the front door :8000, not :8080" {
  run grep '^argocd-ui:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"argocd.127.0.0.1.nip.io:8000"* ]]
}

# --- scripts/ondemand-budget-check.sh ------------------------------------------
# 2026-08-05 incident: Harbor, Istio, Kiali, Longhorn, Kargo, and TiDB all
# ended up running simultaneously across unrelated debugging sessions (each brought
# one up, none brought it back down), exhausting the 12 GB Colima VM's documented
# budget (docs/00-architecture.md "Why on-demand for heavy components") and taking
# every front-door UI down. This script is the mechanical guard.
@test "ondemand-budget-check.sh exists" {
  [ -f "$BUDGET" ]
}

@test "ondemand-budget-check.sh is executable" {
  [ -x "$BUDGET" ]
}

@test "ondemand-budget-check.sh tracks all six documented heavy on-demand units" {
  for unit in harbor istio kiali longhorn kargo tidb; do
    run grep -q "\[$unit\]=" "$BUDGET"
    [ "$status" -eq 0 ]
  done
}

# 2026-08-05 same-session regression: the root app-of-apps declares these Application
# objects in git, so ArgoCD recreates a deleted one on its next auto-sync — existence
# alone is true FOREVER once a unit has ever been brought up once, permanently
# false-positiving the guard. Must key off health.status, not `kubectl get` exit code.
@test "ondemand-budget-check.sh checks Application health, not mere existence (root app-of-apps recreates deleted Applications)" {
  run grep -q "status.health.status" "$BUDGET"
  [ "$status" -eq 0 ]
  run grep -q '!= "Missing"' "$BUDGET"
  [ "$status" -eq 0 ]
  # the old, wrong pattern must be gone
  run grep -q 'kubectl get application -n argocd "\$app" >/dev/null 2>&1 && return 0' "$BUDGET"
  [ "$status" -eq 1 ]
}

# 2026-08-07 regression: health.status alone still false-positives. A freshly
# recreated Application (root's selfHeal) with one leftover resource ArgoCD's
# foreground-cascade delete doesn't remove (observed: a PersistentVolumeClaim)
# rolls the aggregate health up to "Healthy" with zero live workload pods —
# `harbor` reported up for hours after `make harbor-down`. Require an actual
# Pod in the unit's own namespace(s) as the authoritative signal.
@test "ondemand-budget-check.sh also requires a live Pod in the unit's namespace, not just Application health" {
  run grep -q "declare -A UNIT_NS=" "$BUDGET"
  [ "$status" -eq 0 ]
  run grep -q 'kubectl get pods -n "\$ns"' "$BUDGET"
  [ "$status" -eq 0 ]
  run grep -q 'pod_count' "$BUDGET"
  [ "$status" -eq 0 ]
}

@test "ondemand-budget-check.sh maps all six units to a namespace for the Pod check" {
  for unit in harbor istio kiali longhorn kargo tidb; do
    run bash -c "grep -A10 'declare -A UNIT_NS=' '$BUDGET' | grep -q '\[$unit\]='"
    [ "$status" -eq 0 ]
  done
}

@test "ondemand-budget-check.sh flags orphaned on-demand namespaces (no owning Application)" {
  run grep -q "ORPHANS" "$BUDGET"
  [ "$status" -eq 0 ]
}

@test "ondemand-budget-check.sh supports a --pre <unit> mode for blocking pre-flight use" {
  run grep -q -- '--pre)' "$BUDGET"
  [ "$status" -eq 0 ]
}

@test "ondemand-budget-check.sh has a force override, never a silent skip of the report" {
  run grep -q "ONDEMAND_BUDGET_FORCE" "$BUDGET"
  [ "$status" -eq 0 ]
}

@test "Makefile guards every heavy *-up target with ondemand-guard" {
  for t in harbor-up istio-up kiali-up longhorn-up kargo-up tidb-up; do
    run grep -A2 "^$t:" "$MAKEFILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ondemand-guard"* ]]
  done
}

@test "Makefile ondemand-budget-check target invokes ondemand-budget-check.sh" {
  run grep -A1 '^ondemand-budget-check:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ondemand-budget-check.sh"* ]]
}

@test "lab-health-check.sh reports the on-demand budget informationally (never flips PASS/FAIL)" {
  run grep -q "ondemand-budget-check.sh" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}

# --- scripts/k3s-datastore-health-check.sh -------------------------------------
# 2026-08-11 incident: k3s's kine background compactor on k3d-k8s-lab-server-0 went
# silent for 16 straight days after a burst of "Compact failed" errors, letting
# state.db balloon to 505MB and turning routine kine queries into multi-second full
# table scans — degrading the apiserver cluster-wide (TLS handshake timeouts,
# Handler timeouts), not just one pod. See docs/incident-log.md and docs/DR.md's
# "k3s embedded datastore" recovery cookbook. This script is the mechanical guard.
@test "k3s-datastore-health-check.sh exists" {
  [ -f "$DATASTORE" ]
}

@test "k3s-datastore-health-check.sh is executable" {
  [ -x "$DATASTORE" ]
}

@test "k3s-datastore-health-check.sh checks state.db size, compaction gap, and Slow SQL volume" {
  run grep -q "state.db" "$DATASTORE"
  [ "$status" -eq 0 ]
  run grep -q "COMPACT compacted from" "$DATASTORE"
  [ "$status" -eq 0 ]
  run grep -q "Slow SQL" "$DATASTORE"
  [ "$status" -eq 0 ]
}

# The whole point: this must diagnose datastore degradation even when it's itself the
# reason kubectl/apiserver calls are timing out — so it must never depend on kubectl.
# (Excludes comment lines: the header explains *why* it avoids kubectl, which itself
# mentions the word — only actual code lines matter here.)
@test "k3s-datastore-health-check.sh never shells out to kubectl (docker logs/exec only)" {
  run bash -c "grep -vE '^\s*#' '$DATASTORE' | grep -q kubectl"
  [ "$status" -eq 1 ]
}

@test "k3s-datastore-health-check.sh derives the container name from CLUSTER (blue/green support)" {
  run grep -q 'CLUSTER="\${CLUSTER:-k8s-lab}"' "$DATASTORE"
  [ "$status" -eq 0 ]
  run grep -q 'CONTAINER="k3d-\${CLUSTER}-server-0"' "$DATASTORE"
  [ "$status" -eq 0 ]
}

@test "k3s-datastore-health-check.sh exits non-zero when the target container isn't running" {
  run env CLUSTER=nonexistent-cluster-$$ bash "$DATASTORE"
  [ "$status" -ne 0 ]
}

@test "Makefile k3s-datastore-health-check target invokes k3s-datastore-health-check.sh" {
  run grep -A1 '^k3s-datastore-health-check:' "$MAKEFILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"k3s-datastore-health-check.sh"* ]]
}

@test "lab-health-check.sh reports k3s datastore health informationally (never flips PASS/FAIL)" {
  run grep -q "k3s-datastore-health-check.sh" "$HEALTHCHECK"
  [ "$status" -eq 0 ]
}
