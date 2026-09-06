# ADR-0031 — TiDB Operator version-pin policy: hold at the 1.6.x line

**Status.** Removed 2026-09-06 (maintainer decision — TiDB dropped from the lab entirely,
no replacement). All `gitops/tidb/`, `gitops/tidb-admin/`, `gitops/tidb-demo/`,
`gitops/platform/tidb-operator.yaml`, `gitops/platform/tidb-cluster.yaml`,
`gitops/platform/tidb-demo.yaml`, `gitops/platform/tidb-admin-extras.yaml` manifests, the
`lab-tidb.json`/`tidb-demo.json` dashboards, and every tidb-operator-up/tidb-operator-down/
tidb-up/tidb-down/tidb-demo-up/tidb-demo-down Makefile target, test, and cross-reference
were deleted in the same change (see ADR-0032 for the paired database version-pin policy,
also removed). The decision record below is kept for history but no longer describes
anything live in the repo — do not treat any manifest path or Makefile target named below
as still existing.

~~**Status.** Adopted. Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
is new ground, not a supersession; no existing ADR governs TiDB Operator's own version).~~

---

## Context

`gitops/platform/tidb-operator.yaml` pins `targetRevision: 1.6.5` — an explicit, exact
version, not a floating tag. But unlike every other pinned dependency this lab tracks
(Longhorn — [ADR-0013](adr-0013-longhorn-block-storage.md) §Re-evaluation log; k3s —
[ADR-0030](adr-0030-pin-k3s-version-explicitly.md); Vault, RabbitMQ — ADR-0009's own
image-pin note), **TiDB Operator's pin has no governing decision record at all.**
Verified directly (not assumed, ADR-0004): grepped every file under `docs/decisions/`
for "tidb" — the only hits are incidental mentions in ADR-0001, ADR-0009, ADR-0011,
ADR-0012, ADR-0013, ADR-0016, ADR-0017, ADR-0019, ADR-0021, and ADR-0028 (namespace
lists, NetworkPolicy scope tables, PSS profile tables) — none of them record *why*
`1.6.5`, or what would justify moving off it. This is the same class of gap ADR-0030
closed for k3s: a real, un-auditable version pin.

This gap surfaced concretely during a planner-fallback currency sweep 2026-08-05
(`docs/backlog/2026-08-05-action-needed-cycle21-longhorn-hold-reconfirmed-tidb-operator-v2-flagged.md`):
`git ls-remote --tags pingcap/tidb-operator` shows `v2.0.1` as the newest tag, with
`v2.0.0` a full **major** line past the pinned `v1.6.5` — 202 commits in the
`v1.6.5..v2.0.0` range. TiDB Operator v2 is a publicly-documented substantial rewrite:
a redesigned reconciliation architecture and a different CRD API group from v1 (not a
drop-in chart-version bump the way Longhorn 1.11→1.12 or kube-state-metrics 8.0→8.1
are). No v1.6.x end-of-life notice or CVE was found in a targeted grep sweep of the
`pingcap/tidb-operator` commit history — there is no forcing security function today.

TiDB itself is a **heavy/on-demand component** (CHARTER "Target end-state"), never
auto-synced — `gitops/platform/tidb-operator.yaml` has no `automated:` block, brought
up only via make tidb-up. A version-pin decision here carries **zero live-cluster
blast radius** until the maintainer next runs that target.

---

## Decision

**Hold `tidb-operator` at the `1.6.x` line (currently `1.6.5`) until one of this ADR's
flip conditions fires.** A v1→v2 migration is a deliberate, scoped project — new CRDs,
a new reconciliation model, and (per PingCAP's own v2 migration guidance) a distinct
upgrade path from a v1 cluster — not a routine currency bump the executor's
smallest-safe-delta mandate covers. Migrating without a dedicated RFC that plans the
CRD/API transition would risk shipping a config this lab has never actually rendered
or validated against the new operator's schema (ADR-0004: don't assert a posture the
lab hasn't verified).

This mirrors ADR-0013's Longhorn precedent exactly: a technically-available bump is
not, by itself, a reason to take it when the *reason* for holding is architectural
surface area, not staleness.

### Flip conditions (next re-evaluation)

Re-open this decision when **any** of the following occurs:

1. A CVE or security advisory is filed against the `1.6.x` line (or the specific
   `1.6.5` pin).
2. The `1.6.x` line reaches its own end-of-support window (PingCAP's TiDB Operator
   support policy — verify the then-current policy at re-evaluation time, don't
   assume this ADR's snapshot is still accurate).
3. A CHARTER goal or ROADMAP item makes TiDB itself (not just its operator) a
   higher-priority always-on/near-term target, at which point the v2 migration
   should be scoped as its own RFC rather than deferred further.
4. The `1.6.x` line stops receiving patch releases entirely (a soft-EOL signal even
   without a formal end-of-support date).

When a flip condition fires, the next architect-fallback pass should author a
dedicated RFC scoping the v1→v2 migration (CRD changes, `gitops/platform/tidb-operator.yaml`
`valuesObject` re-mapping, `tidb-cluster`/`tidb-demo` manifest compatibility) rather
than a bare version bump — this ADR's job is only to record *that* the hold is
deliberate, not to pre-author that migration.

---

## Consequences

- `gitops/platform/tidb-operator.yaml`'s `targetRevision: 1.6.5` is unchanged by this
  ADR — this is a governance record, not a code change.
- Future currency sweeps that find a newer `1.6.x` patch release (not a `2.x` major)
  remain in scope for a routine executor bump, same as any other component — this ADR
  only governs the major-line question.
- `docs/decisions/README.md` gains an ADR-0031 entry so this decision is discoverable
  the same way every other pinned dependency's is.

## ADR-0004 caveat

This remote, clusterless session verified the upstream tag/commit-range facts above
directly against real `pingcap/tidb-operator` sources, but cannot verify what a live
v2 migration would actually require against this lab's real `tidb`/`tidb-admin`
manifests — that verification is explicitly deferred to whichever future RFC scopes
the migration, per the flip-condition note above.
