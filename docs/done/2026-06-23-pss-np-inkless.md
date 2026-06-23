# PSA baseline + NetworkPolicy — `inkless` namespace (RFC #257)

**CHARTER Objective O2** (PSS-restricted fan-out, due 2026-09-30).

Closes O2 fan-out for the last on-demand namespace missing PSA labels and a
NetworkPolicy floor. Follows the same shape as `auto/pss-np-lab-demo`.

## Files delivered

| Path | Role |
|------|------|
| `gitops/inkless/namespace.yaml` | Namespace manifest with all four PSA `baseline` labels |
| `gitops/inkless/networkpolicy/kustomization.yaml` | Kustomize overlay referencing shared baseline templates + 3 allow files |
| `gitops/inkless/networkpolicy/allow-inkless-intra-namespace.yaml` | Broad intra-namespace ingress+egress (broker↔postgres JDBC, kafka-load→broker, KRaft internal) |
| `gitops/inkless/networkpolicy/allow-inkless-garage-egress.yaml` | Egress TCP 3900 to `storage` namespace for Garage S3 (ADR-0002) |
| `gitops/inkless/networkpolicy/allow-inkless-metrics-ingress.yaml` | Ingress TCP 9308 from `observability` for Kafka exporter scrape |
| `gitops/platform/networkpolicy-appset.yaml` | Added `inkless-networkpolicy` list-generator entry (auto-synced via appset) |
| `docs/decisions/adr-0017-pod-security-standards-restricted.md` | Added `inkless → baseline` row citing RFC #257; flip condition documented |
| `tests/lib/networkpolicy-paths.bash` | Added `INKLESS_NP` path variable |
| `tests/securitycontext-inkless.bats` | 6 bats assertions: namespace exists, enforce/warn/audit baseline, enforce-version:latest, NOT restricted |
| `tests/networkpolicy-inkless.bats` | 12 bats assertions: kustomization, baseline refs, all allow files exist + target correct ports/selectors, appset entry |

## Why baseline (not restricted)

The Aiven Inkless broker image (`ghcr.io/aiven/inkless:latest`) runs as root
UID 0 — no `USER` instruction in the base image. PSS `restricted` would reject
the broker pod at admission. PSS `baseline` blocks privileged containers and
host-namespace use while permitting the root UID.

**Flip condition:** when `ghcr.io/aiven/inkless` ships with an explicit non-root
`USER` directive (see ADR-0017 §Per-namespace profile, inkless row).

## Implementation note: namespace.yaml in gitops/inkless/

The ROADMAP spec called for a separate `inkless-extras.yaml` Application following
the `argocd-extras` / `kyverno-extras` convention. This was not created because
`gitops/inkless/` already contains workload manifests managed by the on-demand
`inkless.yaml` Application — a second auto-synced Application pointing to the same
path would always deploy the workloads, violating the on-demand budget constraint
(ADR-0015). Instead, `namespace.yaml` is placed in `gitops/inkless/` and applied
by the existing `inkless.yaml` Application when the user runs `make inkless-up`.
The NetworkPolicy is deployed via the always-on `networkpolicy-appset.yaml`
ApplicationSet (wave 4), so the deny-floor is in place independently of the
workload lifecycle.

## PR

PR to be filled in.
