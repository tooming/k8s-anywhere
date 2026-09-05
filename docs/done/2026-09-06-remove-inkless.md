# Remove Aiven Inkless (diskless Kafka) entirely — user-directed cleanup

Maintainer decision (2026-09-06): drop Aiven Inkless from the lab entirely, no
replacement. ADR-0015's own experiment (demonstrating KIP-1150's diskless-Kafka
architecture) is retired. This is a straight removal, not a supersession — there
is no new ADR "replacing" ADR-0015 the way ADR-0018 replaced ADR-0010.

## What changed

**Deleted:**
- `gitops/inkless/` (whole directory — namespace, StatefulSets, Service,
  ExternalSecret, kafka-load, NetworkPolicy overlay)
- `gitops/platform/inkless.yaml` (the on-demand ArgoCD Application)
- `gitops/storage/networkpolicy/allow-garage-s3-from-inkless.yaml`
- `gitops/velero/schedules/inkless-daily.yaml`
- `grafana/dashboards/lab-inkless.json`
- `tests/inkless.bats`, `tests/networkpolicy-inkless.bats`,
  `tests/securitycontext-inkless.bats`

**Edited (removed inkless references from live/current-state content):**
- `Makefile` — `inkless-up`/`inkless-down` targets, `dr-restore`'s namespace
  list, `ondemand-budget-check`'s unit lists and comments
- `CHARTER.md`, `README.md`, `docs/00-architecture.md`, `docs/DR.md` — every
  "current state" list/table (stateful namespaces, on-demand components, dashboard
  list, Velero schedule table)
- `docs/dependency-register.md` (dropped the Inkless row; fixed the scope note's
  row-count arithmetic 38→37), `docs/dependency-tree.md` (subgraph, edges, appset
  list, dashboard rows, NetworkPolicy bullets), `docs/dependency-concentration.md`,
  `docs/dora-audit-readiness.md`
- `docs/decisions/adr-0015-inkless-diskless-kafka.md` — Status flipped to
  **Removed 2026-09-05**; the decision record itself is kept for history (why
  Inkless was adopted, what it demonstrated) but no longer describes anything
  live — the `**Status.**` line change is intentionally *not* worded
  "Superseded by" (there's no replacement ADR) since `scripts/readme-check.sh`'s
  ADR exemption only recognizes that literal phrase; the historical `make`-target
  mentions inside the body were reworded (no bare `` `make inkless-up` `` left)
  so the check still passes on a doc it can no longer treat as exempt-by-status.
- `docs/decisions/README.md` — ADR-0015 index entry marked removed
- `docs/decisions/adr-0016-default-deny-networkpolicy.md`,
  `adr-0017-pod-security-standards-restricted.md`,
  `adr-0021-velero-backup-restore.md` — dropped the current-state
  table rows/lists naming `inkless` (namespace lists, PSA profile table,
  Velero Schedule table); their historical Re-evaluation log entries are
  left untouched, same as every other dated decision-log entry in this repo
- `scripts/dr-restore.sh`, `scripts/garage-bootstrap.sh`,
  `scripts/lab-health-check.sh`, `scripts/ondemand-budget-check.sh`,
  `scripts/vault-bootstrap.sh` — removed inkless from namespace/unit lists,
  removed the inkless Garage key/bucket + Vault secret provisioning
- `tests/dr-restore.bats`, `tests/lab-ops-scripts.bats`,
  `tests/lib/networkpolicy-paths.bash`, `tests/networkpolicy-storage.bats`,
  `tests/networkpolicy-velero.bats`, `tests/velero.bats` — dropped
  assertions for deleted files/removed config
- 5 `allow-*-intra-namespace.yaml` header comments (argocd, harbor, istio-system,
  longhorn, tidb) that cross-referenced ADR-0016's carve-out table by an
  `argocd/harbor/inkless/...` name list

**Left untouched (deliberate):** `docs/backlog/*`, `docs/done/*` (other than
this new entry), and `ROADMAP.md`'s historical `[x]` narrative lines — these are
dated records of work actually done at the time and remain accurate as history,
the same convention this repo already applies to every other removed/superseded
component (e.g. ADR-0010/Redis, ADR-0011/Artifactory). `tests/kyverno.bats`'s
regression guard asserting the (already-historical) `disallow-latest-tag`
`inkless` carve-out stays removed was also left in place, matching the
still-kept `argocd` carve-out regression guard right above it.

## Verification

- `bash scripts/kustomize-orphan-check.sh`, `bash scripts/readme-check.sh`,
  `bash scripts/dependency-register-check.sh`, `bash scripts/lint.sh` — all clean.
- Full `bats tests/` — green (see PR for the exact count).
- `git grep -i inkless` across the repo now only matches: the ADR-0015 file
  itself (its removal record), `docs/decisions/README.md`'s index line, five
  ADRs' historical Re-evaluation-log narrative, and historical `docs/backlog/`
  `docs/done/` entries and `ROADMAP.md` `[x]` lines — no live config, script, or
  test references the component.

## PR

https://github.com/tooming/k8s-anywhere/pull/REPLACE_ME
