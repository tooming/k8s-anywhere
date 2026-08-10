# Janitor note — 2026-08-10 (README.md's Endpoints table missing two on-demand UIs)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, fourteenth cycle
this run. Fifth consecutive subagent-delegated deep gap-analysis sweep (following
cycles 10-13's real ADR-0019/ADR-0016/ADR-0021/dependency-register findings), this
time targeting README.md and docs/00-architecture.md against real `gitops/` state.

**What was found:** README.md's `## Endpoints` table — the canonical, human-facing
list of UIs served through the `:8000` front door — was missing two on-demand
components with real, live `HTTPRoute`s: **Harbor**
(`harbor.127.0.0.1.nip.io`, `gitops/harbor/route.yaml`) and **TiDB demo**
(`tidb-demo.127.0.0.1.nip.io`, `gitops/tidb-demo/route.yaml`). Both are already
correctly listed in `grafana/dashboards/stack-health.json`'s "Lab UIs" panel and
mechanically enforced there by `scripts/lab-ui-check.sh` — but that check only ever
compared the Grafana panel against `gitops/` HTTPRoutes, never README.md's own
table, so this specific list had no guard and had silently gone stale.

**This is a genuine bugfix, not just a doc-precision correction** — a real,
already-live UI was undiscoverable from the repo's own primary onboarding doc. Per
CLAUDE.md's "every bugfix must prevent recurrence" rule, this gets a proper
mechanical guard, not just a content fix:

1. **Fix:** added Harbor and TiDB demo rows to README.md's Endpoints table
   (`*(on-demand)*` marker, matching the existing Kiali/Longhorn/Kargo rows).
2. **Guard:** extended `scripts/lab-ui-check.sh` (already the exact mechanism for
   this class of drift, applied only to the Grafana panel before) to *also* compare
   README.md's `## Endpoints` section against the same `gitops/` HTTPRoute source
   of truth — same missing/stale-row logic, scoped to just that section (via `awk`)
   so a stray host-like string elsewhere in the doc, e.g. the wildcard cert-manager
   note, is never mistaken for an endpoint row.
3. **Test coverage:** two new fixture trees
   (`tests/fixtures/lab-ui-check/readme-missing/`, `.../readme-stale/`) and two new
   `@test` cases in `tests/drift-detectors.bats` (README.md's own Endpoints-table
   drift is now caught the same way panel drift already was); `make
   drift-detectors-tests-mark` run to refresh the frozen-monolith snapshot, per
   this repo's established pattern (adding tests to an *existing* scope within a
   frozen monolith, not creating a new drift-check type, so no new `tests/drift-
   <scope>.bats` file was warranted).
4. **Hook wiring:** `scripts/lab-ui-sync-hook.sh` (the PostToolUse companion) now
   also reacts to edits to README.md itself, not just `stack-health.json`/HTTPRoute
   manifests — so editing the Endpoints table by hand and accidentally dropping a
   row is caught immediately, not just on the next `make ci`. New `@test` case in
   `tests/hook-scripts-coverage.bats` (mark step run for the same frozen-monolith
   reason as above).

Existing `lab-ui-check` fixtures (`in-sync`/`drift`/`port-drift`) needed no changes
— the script's README-comparison logic is skipped entirely when no `README.md`
exists at the fixture root, so those pre-existing tests are unaffected.

**Sweep scope this cycle (for the record):** README.md's `brew install` tool list,
`make` target references, port claims, and `gitops/` layout description were all
cross-checked against the Makefile/repo structure and found accurate (the only real
gap was the Endpoints table). The subagent's report also flagged a possible
dashboard-list section as incomplete, but no such list actually exists in
README.md (re-checked directly, found nothing matching that description) — not
acted on, since I only assert what I've personally verified (ADR-0004). Did not
reach docs/00-architecture.md, docs/decisions/README.md's index, or the
governance-ADR spot-checks (ADR-0003/0005/0025/0026/0030) this cycle.
