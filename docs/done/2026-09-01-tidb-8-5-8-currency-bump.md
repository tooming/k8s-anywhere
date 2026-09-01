# Bump TiDB database version `v8.5.7` → `v8.5.8` — routine currency, same held line

(CHARTER **Core Values** §"Everything as code" + general hardening; upgrade-drafter fallback, executor.prompt.md STEP 6b — this run's fourth cycle: the "Now / next" lane remained fully gated (two GitLab→Forgejo migration items + the capstone-`Deployment`-removal item, all blocked on unconfirmed live-cluster prerequisites — issues #633/#1229/#1345, unchanged since 2026-08-25), PLANNER found no ungroomed intake or un-RFC'd 🟡 item. This cycle's own dependency-currency sweep, done while preparing this run's architect-fallback industry digest, surfaced TiDB `v8.5.8` as a real candidate.)

[ADR-0032](../decisions/adr-0032-tidb-version-policy.md) holds the TiDB database at the `v8.5.x` LINE (a deliberate hold on the `v26.x` calendar-versioning scheme jump, unrelated to patch currency) but explicitly carves out routine patch bumps within that line: *"A future `v8.5.z` patch (not the `v26.x` line) remains in scope for a routine upgrade-drafter bump — this ADR only governs the version-scheme jump."* This bump stays entirely within that carve-out.

Verified directly (not assumed, ADR-0004): the GitHub tag/release HTML page's rendered publish date proved unreliable in this sandbox (showed "2024" for a release that is unambiguously from the current run's timeframe) — cross-checked against the real Atom feeds instead (`github.com/pingcap/tidb/tags.atom` and `.../releases.atom`), whose raw XML carries an explicit ISO-8601 `<updated>` field: "TiDB v8.5.8" published `2026-08-27T09:06:37Z`. Confirmed this is the newest *plain release* tag on the `v8.5.x` line — only nightly/commit-titled build tags (e.g. `v8.5.8-20260829-c5ce6ce`) exist beyond it, not further stable releases, matching this repo's "skip non-semver moving tags" policy.

Could not retrieve specific fix content for this release: `docs.pingcap.com` (where GitHub's own release page points for the changelog) is proxy-blocked in this sandbox, and the GitHub compare view (`v8.5.7...v8.5.8`, 39 commits / 156 files changed) was too large to render individual commit messages. This is treated as a routine currency bump — the same evidence bar (newest stable tag, no major-version jump, no ADR-line crossed) this repo's original `v8.1.2` → `v8.5.7` bump used — not a claimed security fix.

Bumped `gitops/tidb/tidb-cluster.yaml`'s `spec.version: "v8.5.7"` → `"v8.5.8"` and its header comment block. Updated `tests/tidb-cluster.bats`'s pin assertion (retitled). Updated `docs/dependency-register.md`'s TiDB row.

**ADR-0004 caveat.** This remote clusterless session cannot verify `tidb-operator` `1.6.6` reconciles this database version cleanly on a live cluster — TiDB is on-demand (`make tidb-up`), not currently running. Rollback path: revert `spec.version` back to `"v8.5.7"`; ADR-0005's recreate-over-HA means `make tidb-down && make tidb-up` rebuilds the cluster from manifest with no state to lose beyond the demo data itself.

## PR

(filled in after PR creation)
