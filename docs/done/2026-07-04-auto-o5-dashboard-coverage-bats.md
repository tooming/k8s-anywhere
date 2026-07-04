# O5 dashboard-coverage bats — always-on service apps

CHARTER **Objective O5**, due **2026-09-30**; O5 says "measured by a drift
check wired into make ci" but the current CI only checks HTTPRoute ↔
panel sync via `lab-ui-check.sh` — it does NOT verify that each
always-on service app has a `lab-<name>.json` file. This item adds
the O5 measurement mechanism as bats assertions; no Makefile change
needed — bats already runs in `scripts/test.sh` which is in
`make ci`). Add to `tests/observability.bats` (or a new
`tests/dashboard-coverage.bats`) one `@test` block per always-on
service application verifying its `grafana/dashboards/lab-<name>.json`
exists and contains at least one reference to `"uid": "mimir"` (a
real Mimir datasource panel, not a stub — ADR-0004). Cover these
apps (18 total): `argo-rollouts` → `lab-argo-rollouts.json`;
`capstone` → `lab-capstone.json`; `data-demo` → `lab-data-demo.json`;
`demo` → `lab-demo.json`; `envoy-gateway` → `lab-envoy.json`;
`external-secrets` → `lab-external-secrets.json`; `garage` →
`lab-garage.json`; `kro` + `moto` + `ack-s3` → `lab-cloud-control-plane.json`;
`kyverno` → `lab-kyverno.json`; `observability-alloy` → `lab-alloy.json`;
`observability-grafana` → `lab-grafana.json`; `observability-ksm` →
`lab-ksm.json`; `observability-loki` → `lab-logs.json`;
`observability-mimir` → `lab-mimir.json`;
`observability-node-exporter` → `lab-node-exporter.json`;
`observability-pyroscope` → `lab-profiles.json`;
`observability-tempo` → `lab-traces.json`; `rabbitmq` →
`lab-rabbitmq.json`; `s3manager` → `lab-s3manager.json`;
`trivy-operator` → `lab-trivy.json`; `valkey` → `lab-valkey.json`;
`vault` → `lab-vault.json`; `velero` → `lab-velero.json`. Each test
only checks file existence + mimir uid presence — no panel-count
assertions (those are in the per-dashboard tests already). Note: the
multi-app shared dashboard (`lab-cloud-control-plane.json`) is tested
once, citing all three apps it covers. (auto/o5-dashboard-coverage-bats)

## PR

#328
