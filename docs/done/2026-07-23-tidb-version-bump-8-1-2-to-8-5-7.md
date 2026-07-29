# Bump TiDB database version v8.1.2 → v8.5.7

CHARTER **Core Values** §"Everything as code" + general dependency hygiene.
Upgrade-drafter fallback sweep (`executor.prompt.md` STEP 6b) after the
"Now / next" lane came up fully gated on standing maintainer-confirmation
issues #631/#632/#633, and the planner/architect fallback roles found no new
ROADMAP gaps or ADR-audit triggers this cycle.

- Component: `pingcap/tidb` (the `TidbCluster.spec.version` field in
  `gitops/tidb/tidb-cluster.yaml`, on-demand — `make tidb-up`). No ADR pins
  TiDB's database version specifically (only `docs/decisions/context.md`
  notes TiDB is demoed as a heavy on-demand MySQL-compatible database; the
  `tidb-operator` chart pin, `1.6.5`, is a separate, unaffected value).
- From → To: `v8.1.2` → `v8.5.7`.
- Why this version: highest real stable release on `pingcap/tidb`'s GitHub
  releases (confirmed via a direct fetch of the releases page — `v8.5.7`
  published 2026-07-09; `v9.0.0-beta.1` also exists but is a pre-release,
  skipped per policy). Still major `8` — no architect RFC needed (same-major
  bump, per upgrade-drafter's own scope rules).
- **Operator compatibility check:** `pingcap/tidb-operator`'s own upstream
  release stream has moved on to a `2.x` line, but only as alpha/beta
  pre-releases (`v2.2.0-alpha.4`, `v2.1.0-beta.6`) — no stable `2.x` tag
  exists yet, so the `1.6.5` operator chart pin stays (nothing groundable to
  bump to, ADR-0004). TiDB operator releases in the `1.x` line are not
  tightly version-locked to a specific `TidbCluster.spec.version` — they
  support a range of database versions within the same major line.
- **ADR-0004 caveat:** this remote clusterless session cannot verify
  `tidb-operator` 1.6.5 actually reconciles a `v8.5.7` cluster cleanly on a
  live host (TiDB is on-demand; no cluster is reachable from this session).
  Rollback path: revert the one-line `version:` field; per ADR-0005
  (recreate-over-HA on a single host), `make tidb-down && make tidb-up`
  rebuilds the cluster from manifest, with no state lost beyond the demo
  data itself.

Added `tests/tidb-cluster.bats` (new file — no prior bats coverage asserted
this version pin at all) with three assertions: the manifest exists, the
pin is a real `8.x` semver, and the pin is at least `v8.5.7` — a recurrence
guard mirroring this repo's other per-component version-pin assertions
(e.g. `tests/argo-rollouts.bats`). No topology change, so no
README/`docs/dependency-tree.md` update — neither references a TiDB version
number today (verified: `grep -n -i tidb docs/dependency-tree.md` shows no
version string, only topology labels).

`make ci` must pass. `docs/backlog/` note for this cycle: this is the honest,
concrete deliverable found after re-checking `Now / next` (still fully gated
on #631/#632/#633) and running a fresh upstream sweep across every ADR'd
component's release feed — Longhorn, Kyverno, cert-manager, Kargo, Vault,
ArgoCD, and Trivy Operator were all already current or had nothing groundable
to bump; TiDB (deliberately outside the ADR'd list — no ADR governs it) was
the one real, actionable gap found.

## PR

[#679](https://github.com/tooming/k8s-anywhere/pull/679)
