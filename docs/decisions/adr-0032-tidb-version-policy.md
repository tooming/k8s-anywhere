# ADR-0032 — TiDB database version-pin policy: hold at the `v8.5.x` line

**Status.** Adopted. Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
is new ground, not a supersession; no existing ADR governs the TiDB database's own
version — [ADR-0031](adr-0031-tidb-operator-version-policy.md) governs the *Operator*
only, a distinct component).

---

## Context

`gitops/tidb/tidb-cluster.yaml`'s `spec.version: "v8.5.7"` is an explicit, exact pin —
bumped there by a prior upgrade-drafter run (2026-07-23) whose own inline comment
states plainly: "no dedicated ADR pins the TiDB database version... this is a routine
same-major currency bump, not an architect decision." That gap is real and is this
ADR's subject. Verified directly (not assumed, ADR-0004): grepped every file under
`docs/decisions/` for "tidb" — the only hits are ADR-0031 (the Operator's own pin
policy, which explicitly scopes itself to `gitops/platform/tidb-operator.yaml`, a
different resource) and incidental namespace/table mentions in ADR-0001, ADR-0009,
ADR-0011, ADR-0012, ADR-0013, ADR-0016, ADR-0017, ADR-0021, ADR-0028. None records why
`v8.5.7`, or what would justify moving off it — the same class of gap ADR-0031 closed
for the Operator a day earlier (2026-08-05), now found in the database's own version
field.

This surfaced during this run's resumed industry-digest sweep (`docs/industry/2026-W32-digest.md`):
`git ls-remote --tags pingcap/tidb` shows `v8.5.7` is still the newest tag on the
`v8.5.x` line (no `v8.5.8` yet) — so no routine patch is being left on the table. But
the newest tags *overall* are `v26.3.9` and siblings down to `v26.3.0` (published
starting shortly after `v9.0.0-beta.1`/`v9.0.0-beta.2.pre`) — PingCAP has moved TiDB
off semantic versioning onto **calendar versioning** (`v26.x` = a 2026 release line),
skipping the `v9`/`v10`/… semver sequence entirely. This is a materially bigger jump
than ADR-0031's `v1→v2` Operator finding: not just a major-version bump but a
version-*scheme* change, meaning "smallest safe delta" has no natural meaning here —
there is no `v9.x`/`v10.x` stepping stone to move to first. Whether `v26.3.x` is even
compatible with `tidb-operator` `1.6.x` (held per ADR-0031) is unverified and, per that
ADR's own flip conditions, out of scope until a dedicated migration is actually scoped.

TiDB is a **heavy/on-demand component** (CHARTER "Target end-state"), never
auto-synced — `gitops/tidb/tidb-cluster.yaml` deploys only via `make tidb-up`. A
version-pin decision here carries **zero live-cluster blast radius** until the
maintainer next runs that target.

---

## Decision

**Hold the TiDB database at the `v8.5.x` line (currently `v8.5.7`) until one of this
ADR's flip conditions fires.** Moving to the `v26.x` calendar-versioned line is a
deliberate, scoped project — an unknown compatibility surface against the
ADR-0031-held `tidb-operator` `1.6.x`, and PingCAP's own upgrade path documentation for
the scheme change needs to be read before committing to it — not a routine currency
bump the executor's or upgrade-drafter's smallest-safe-delta mandate covers. This
mirrors ADR-0031's Operator precedent exactly: the *reason* for holding is unresolved
architectural/compatibility surface area, not staleness — no CVE or `v8.5.x`
end-of-support signal was found in a targeted check of PingCAP's release notes.

A future `v8.5.z` patch (not the `v26.x` line) remains in scope for a routine
upgrade-drafter bump — this ADR only governs the version-scheme jump, exactly as
ADR-0031 only governs the Operator's major-line jump.

### Flip conditions (next re-evaluation)

Re-open this decision when **any** of the following occurs:

1. A CVE or security advisory is filed against the `v8.5.x` line (or the specific
   `v8.5.7` pin).
2. The `v8.5.x` line reaches its own end-of-support window (verify PingCAP's
   then-current support policy at re-evaluation time, don't assume this ADR's
   snapshot is still accurate).
3. `tidb-operator` moves off its own ADR-0031 hold (a `v2.x` Operator migration is
   scoped) — at that point TiDB's own version should be re-evaluated in the same
   pass, since the two are coupled.
4. A CHARTER goal or ROADMAP item makes TiDB itself a higher-priority always-on/
   near-term target, at which point the version-scheme migration should be scoped as
   its own RFC rather than deferred further.
5. The `v8.5.x` line stops receiving patch releases entirely (a soft-EOL signal even
   without a formal end-of-support date).

When a flip condition fires, the next architect-fallback pass should author a
dedicated RFC scoping the migration (read PingCAP's `v26.x` upgrade documentation,
verify `tidb-operator` compatibility, plan the `tidb-cluster.yaml`/`tidb-demo`
manifest changes) rather than a bare version bump — this ADR's job is only to record
*that* the hold is deliberate, not to pre-author that migration.

---

## Consequences

- `gitops/tidb/tidb-cluster.yaml`'s `spec.version: "v8.5.7"` is unchanged by this
  ADR — this is a governance record, not a code change.
- Future currency sweeps that find a newer `v8.5.z` patch release (not the `v26.x`
  line) remain in scope for a routine executor/upgrade-drafter bump, same as any other
  component — this ADR only governs the version-scheme question.
- `docs/decisions/README.md` gains an ADR-0032 entry so this decision is discoverable
  the same way every other pinned dependency's is.

## ADR-0004 caveat

This remote, clusterless session verified the upstream tag facts above directly
against real `pingcap/tidb` sources (`git ls-remote --tags`), but cannot verify what a
live `v26.x` migration would actually require against this lab's real
`tidb`/`tidb-admin` manifests or `tidb-operator` `1.6.x` compatibility — that
verification is explicitly deferred to whichever future RFC scopes the migration, per
the flip-condition note above.
