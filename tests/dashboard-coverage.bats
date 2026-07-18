#!/usr/bin/env bats
# O5 dashboard-coverage sweep — one existence + datasource-uid assertion per
# always-on service application (CHARTER Objective O5, auto/o5-dashboard-coverage-bats).
#
# Purpose: verify that every always-on ArgoCD Application has a corresponding
# grafana/dashboards/lab-<name>.json that references at least one real datasource
# panel (ADR-0004 — no fabricated/placeholder content). These are additive to the
# per-component bats files; they do not replace the detailed per-dashboard tests.
#
# Datasource uid check per panel type:
#   metric panels  → "uid": "mimir"
#   log panels     → "uid": "loki"   (observability-loki)
#   trace panels   → "uid": "tempo"  (observability-tempo)
#   profile panels → "uid": "pyroscope" (observability-pyroscope)
#
# Collapsed from 25 near-identical per-dashboard test pairs into two loops over
# a shared list (mirrors the STANDARD_NS loop convention in tests/governance.bats)
# — same coverage, same per-item failure diagnostics via the echo-before-return
# pattern, far less duplication to keep in sync by hand.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  DASHBOARDS="$REPO/grafana/dashboards"
}

# Always-on service applications whose dashboard uses the Mimir datasource.
MIMIR_DASHBOARDS="lab-argo-rollouts lab-capstone lab-data-demo lab-demo lab-envoy \
lab-external-secrets lab-garage lab-cloud-control-plane lab-kyverno lab-alloy \
lab-grafana lab-ksm lab-mimir lab-node-exporter lab-rabbitmq lab-s3manager \
lab-trivy lab-valkey lab-vault lab-velero lab-cilium lab-argocd lab-gitsync \
lab-cert-manager lab-keda"

@test "every always-on Mimir-backed dashboard exists" {
  for d in $MIMIR_DASHBOARDS; do
    [ -f "$DASHBOARDS/$d.json" ] || { echo "missing dashboard: $d.json"; return 1; }
  done
}

@test "every always-on Mimir-backed dashboard has a real Mimir datasource panel (ADR-0004)" {
  for d in $MIMIR_DASHBOARDS; do
    run grep -q '"uid": "mimir"' "$DASHBOARDS/$d.json"
    [ "$status" -eq 0 ] || { echo "$d.json: no Mimir datasource panel found"; return 1; }
  done
}

# The three LGTMP dashboards below each use a distinct non-Mimir datasource, so
# they stay as individual tests rather than joining the loop above.

# ---------------------------------------------------------------------------
# observability-loki
# Loki dashboards use the Loki datasource, not Mimir; check "uid": "loki".
# ---------------------------------------------------------------------------

@test "lab-logs.json exists (observability-loki coverage)" {
  [ -f "$DASHBOARDS/lab-logs.json" ]
}

@test "lab-logs.json has real Loki datasource panel (ADR-0004)" {
  run grep -q '"uid": "loki"' "$DASHBOARDS/lab-logs.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-pyroscope
# Pyroscope dashboards use the Pyroscope datasource; check "uid": "pyroscope".
# ---------------------------------------------------------------------------

@test "lab-profiles.json exists (observability-pyroscope coverage)" {
  [ -f "$DASHBOARDS/lab-profiles.json" ]
}

@test "lab-profiles.json has real Pyroscope datasource panel (ADR-0004)" {
  run grep -q '"uid": "pyroscope"' "$DASHBOARDS/lab-profiles.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# observability-tempo
# Tempo dashboards use the Tempo datasource; check "uid": "tempo".
# ---------------------------------------------------------------------------

@test "lab-traces.json exists (observability-tempo coverage)" {
  [ -f "$DASHBOARDS/lab-traces.json" ]
}

@test "lab-traces.json has real Tempo datasource panel (ADR-0004)" {
  run grep -q '"uid": "tempo"' "$DASHBOARDS/lab-traces.json"
  [ "$status" -eq 0 ]
}
