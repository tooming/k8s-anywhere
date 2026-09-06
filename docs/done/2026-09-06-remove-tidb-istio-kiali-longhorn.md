# Remove TiDB, Istio ambient mesh + Kiali, and Longhorn entirely — user-directed cleanup

Maintainer decision (2026-09-06, mid-session while resolving issue #633): drop TiDB,
Istio ambient mesh + Kiali, and Longhorn from the lab entirely, no replacement. Found
live while diagnosing a real resource-contention incident (Harbor + Kargo both up for
#633 verification, plus these three on-demand components accumulated from earlier
debugging sessions, pushed the Colima VM into etcd/CoreDNS instability — see
`docs/incident-log.md`). This is a straight removal, not a supersession — ADR-0012,
ADR-0013, ADR-0031, and ADR-0032 record decisions that are simply retired, the same
shape as ADR-0015/Aiven Inkless's 2026-09-06 removal earlier the same day.

## What changed

**Deleted:**
- `gitops/tidb/`, `gitops/tidb-admin/`, `gitops/tidb-demo/` (whole directories)
- `gitops/platform/tidb-operator.yaml`, `tidb-cluster.yaml`, `tidb-demo.yaml`,
  `tidb-admin-extras.yaml`
- `gitops/velero/schedules/tidb-daily.yaml`
- `gitops/istio-system/`, `gitops/kiali/` (whole directories)
- `gitops/platform/istio-base.yaml`, `istio-cni.yaml`, `istiod.yaml`,
  `istio-system-extras.yaml`, `ztunnel.yaml`, `kiali.yaml`, `kiali-extras.yaml`
- `gitops/longhorn/` (whole directory)
- `gitops/platform/longhorn.yaml`, `longhorn-extras.yaml`
- `grafana/dashboards/lab-tidb.json`, `tidb-demo.json`, `lab-istio.json`,
  `lab-longhorn.json`
- `tests/istio-observability.bats`, `istio-system-extras.bats`, `longhorn.bats`,
  `networkpolicy-istio-system.bats`, `networkpolicy-tidb-admin.bats`,
  `networkpolicy-longhorn-system.bats`, `networkpolicy-tidb.bats`,
  `securitycontext-istio.bats`, `securitycontext-longhorn.bats`,
  `tidb-admin-extras.bats`, `tidb-cluster.bats`, `platform.bats` (wholly dedicated
  to these three components)

**Edited (removed live/current-state references):**
- `Makefile` — `tidb-operator-up/down`, `tidb-up/down`, `tidb-demo-up/down`,
  `istio-up/down`, `kiali-up/down`, `mesh-up/down`, `longhorn-up/down` targets;
  `dr-restore`'s namespace list
- `scripts/ondemand-budget-check.sh` — dropped from `UNIT_APPS`/`UNIT_NS`/`UNIT_SIZE`;
  `ONDEMAND_NS` orphan-detection list kept (same convention as the `artifactory`
  carve-out — stray leftover namespaces from before this removal still get
  correctly flagged as orphaned, not silently ignored)
- `scripts/lab-health-check.sh`, `scripts/dr-restore.sh`, `scripts/coredns-host-alias.sh`
  — comment/list updates
- `CHARTER.md`, `README.md`, `docs/00-architecture.md`, `docs/DR.md` — every
  "current state" list/table (stateful namespaces, on-demand components, dashboard
  list, Velero schedule table)
- `grafana/dashboards/stack-health.json` — dropped the Kiali/Longhorn/TiDB-demo
  Lab-UIs panel rows
- `docs/dependency-register.md` (dropped 5 rows — Istio, Kiali, Longhorn, TiDB
  Operator, TiDB; fixed the scope note's row-count arithmetic 37→32),
  `docs/dependency-concentration.md` (dropped the `github.com/pingcap` group,
  trimmed the distinct-org list), `docs/dependency-tree.md` (3 mermaid subgraphs +
  their edges, appset list entries, dedicated table rows, NetworkPolicy/observability
  bullets), `docs/dora-audit-readiness.md`
- `docs/decisions/adr-0012-istio-ambient-not-sidecar.md`,
  `adr-0013-longhorn-block-storage.md`, `adr-0031-tidb-operator-version-policy.md`,
  `adr-0032-tidb-version-policy.md` — Status flipped to **Removed 2026-09-06**; each
  decision record is kept for history but no longer describes anything live — the
  historical `make`-target mentions inside each body were de-backticked (no bare
  `` `make istio-up` ``-style mentions left) so `scripts/readme-check.sh`'s ADR scan
  still passes on docs it can no longer treat as exempt-by-"Superseded by" status
- `docs/decisions/README.md` — all four ADR index entries marked removed
- `docs/decisions/adr-0016-default-deny-networkpolicy.md`,
  `adr-0017-pod-security-standards-restricted.md`,
  `adr-0021-velero-backup-restore.md` — dropped the current-state table rows/lists
  naming `tidb`/`tidb-admin`/`istio-system`/`longhorn-system` (namespace-in-scope
  counts, PSA profile table, NetworkPolicy carve-out table, Velero Schedule table);
  their historical Re-evaluation log entries are left untouched, same as every
  other dated decision-log entry in this repo
- `gitops/envoy-gateway-system/networkpolicy/allow-envoy-proxy-backend-egress.yaml`,
  `gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml`,
  `gitops/platform/networkpolicy-appset.yaml`,
  `gitops/platform/observability-alloy.yaml` (3 `prometheus.scrape` blocks),
  `gitops/platform/velero-schedules.yaml`,
  `gitops/argocd/networkpolicy/allow-argocd-intra-namespace.yaml`,
  `gitops/harbor/networkpolicy/allow-harbor-intra-namespace.yaml`,
  `gitops/kyverno/policies/add-default-seccomp.yaml`,
  `add-default-runasnonroot.yaml`, `require-pod-security-restricted.yaml` — removed
  functional references (NetworkPolicy allow-lists, appset entries, scrape configs)
  and illustrative example-namespace mentions
- `tests/architecture-doc.bats` (dashboard-count arithmetic 6→2 on-demand-tied),
  `tests/dr-restore.bats`, `tests/velero.bats`, `tests/networkpolicy-velero.bats`,
  `tests/networkpolicy-envoy-gateway-system.bats` (17→14 backend namespaces),
  `tests/lab-ops-scripts.bats`, `tests/securitycontext.bats`,
  `tests/hook-scripts-envoy-egress-allowlist.bats`, `tests/hook-scripts-coverage.bats`
  (swapped a deleted fixture path for `gitops/kargo/route.yaml`), `tests/kyverno.bats`,
  `tests/kyverno-add-default-runasnonroot.bats`, `tests/drift-detectors.bats` — dropped
  assertions for deleted files/config, fixed one stale illustrative-comment example

**Left untouched (deliberate):** `docs/backlog/*`, `docs/done/*` (other than this new
entry), and `ROADMAP.md`'s historical `[x]` narrative lines — dated records of work
actually done at the time, still accurate as history, same convention this repo
already applies to every other removed/superseded component (ADR-0010/Redis,
ADR-0011/Artifactory, ADR-0015/Inkless). A handful of illustrative header comments
(e.g. `cert-manager.yaml`'s memory-bump justification, `garage.yaml`'s bucket-list
comment) that name these components as dated historical context were also left as-is.

## Known pre-existing, unrelated gap found and flagged

`make envoy-egress-allowlist-check` already fails on a clean `main` (before this
change) — it false-positives on a vendored Helm chart CRD schema
(`gitops/envoy-gateway/charts/gateway-helm-v1.8.3/.../gateway.envoyproxy.io_securitypolicies.yaml`)
that happens to contain the literal strings `kind: HTTPRoute` and `namespace: default`
as OpenAPI example content. Confirmed via `git stash` that this predates this session's
work entirely. Flagged as a separate background task rather than folded into this PR.

## Verification

- `make kustomize-orphan-check`, `make readme-check`, `make lab-ui-check`,
  `make dependency-register-check`, `make dependency-concentration-sync-check` — all
  clean.
- Full `bats tests/` — green (see PR for the exact count).
- `git grep -i "tidb\|istio\|kiali\|longhorn"` across `gitops/`, `scripts/`, and
  `Makefile` now only matches illustrative/historical comments — no live config,
  ArgoCD Application, NetworkPolicy rule, or test asserts anything about these three
  components still existing.
