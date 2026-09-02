# Close DORA audit Q15's named gap — add `make dependency-maintenance-check`, a re-checkable maintenance-health report for every `docs/dependency-register.md` row

(CHARTER **Core Values** §"Everything as code" + general dependency hygiene
(DORA audit readiness Q15); planner-fallback gap analysis 2026-09-02, reached
via `executor.prompt.md` STEP 6b after the "Now / next" lane was re-confirmed
fully gated this cycle — both standing GitLab→Forgejo migration items above
remain genuinely blocked (re-verified directly this cycle: `Makefile`'s `up`
target still calls `gitlab-up`/`gitlab-configure` and `down` still calls `cd
gitlab && docker compose stop`, confirming the 2026-08-17 investigation's
finding still holds — removing `gitlab/docker-compose.yml` or
`infra/modules/gitlab-config` today would break `make up`/`make down`
outright, not just the rename item), and the capstone-`Deployment`-removal
item further below is still gated on unconfirmed issue #633 (re-checked this
cycle: latest comment 2026-08-25 16:41 UTC still reports `etcd` readiness
failures blocking Warehouse discovery, unresolved). No ungroomed intake issue
exists (the three open issues are all standing `[Action required]` trackers —
#633, #1229, #1345 — re-confirmed by re-reading each) and no un-RFC'd 🟡 item
exists (zero `- [ ] 🟡` lines in ROADMAP.md this cycle). Fresh angle this
cycle, not yet tried by any prior pass: rather than another dependency
*version-currency* sweep (docs/industry/2026-W36-digest.md's 2026-09-01 entry
already swept every ADR'd component's current version exhaustively one day
prior — re-running that identical sweep a single day later would be low-yield
churn), read `docs/dora-audit-readiness.md` end-to-end for a still-open,
genuinely unaddressed gap and found Q15's: "no scheduled re-check of
maintenance health (is the project still active, still maintained) after
initial adoption" — real, named, and previously untouched by any prior
cycle. **No prerequisites — executor may pick up immediately.**)

Verified directly (not assumed, ADR-0004): `docs/dependency-register.md`'s own
33-row table already cites each dependency's `github.com` upstream source in
its "Upstream source" column — the mechanical raw material this needed
already existed, just unused for a periodic re-check. Built
`scripts/dependency-maintenance-check.sh`: parses the register's own table
(no separate, driftable list of repos to maintain), extracts each row's
`github.com/OWNER/REPO`, and reports days since that repo's default branch
last committed via `git clone --bare --depth 1 --filter=tree:0` +
`git log -1 --format=%cI` (a few hundred KB, ~1-2s per repo). **Deliberately
not using the GitHub REST API** (`api.github.com`): verified directly, live,
this cycle, that this remote clusterless session's own environment gates
`api.github.com`/`github.com` HTTP(S) requests outside its configured repo
scope — every real `curl`/`WebFetch` call against `api.github.com` returned
an access-scope message, not repo data, while the git smart-HTTP protocol
itself (`git clone`) was NOT scoped the same way, confirmed working live
against all ~30 real upstream repos in the register (full sweep: 30/30
resolved, 0 stale past the default 365-day window, ~39s wall-clock). Using
the API anyway would have shipped a tool that silently never functions when
invoked by this repo's own routines (which all run in this same gated
environment) — caught and redesigned before delivery, not after.

A repo with no commit in over a year is flagged "worth a fresh look", never
asserted "unmaintained" — a mature, feature-complete dependency going quiet
is not automatically a problem (ADR-0004: no fabricated verdicts, only a
real, dated signal). **Report-only, deliberately NOT wired into `make ci`**
(a ~30-repo network sweep is unsuitable as a hard, always-on gate) — added as
`make dependency-maintenance-check` in the Makefile's existing "Metrics
(on-demand, clusterless)" section, alongside `dora-metrics`, matching that
target's own "on-demand, no scheduler" shape; a future architect/janitor
cycle is the intended periodic invoker, same as this repo's industry digest
already works. Network-tolerant by design, mirroring
`helm-chart-pin-check.sh`: an unreachable clone is SKIPPED, never treated as
evidence of staleness. Added `tests/dependency-maintenance-check.bats` (6
cases: fresh/stale/no-source/unreachable/wide-window-pass/missing-register)
resolved offline via a `DEPMAINT_RESOLVER` stub fixture
(`tests/fixtures/dependency-maintenance-check/`), mirroring
`tests/drift-gitops-manifest-checks.bats`'s `CHARTPIN_RESOLVER` pattern so
the suite never hits the network. Updated `docs/dora-audit-readiness.md`'s
Q15 answer/gap to cite the new mechanism and narrow (not close) the gap: the
re-check tool now exists and is real, but nothing yet schedules its
invocation automatically. No README.md change needed (verified directly:
`dora-metrics`/`ondemand-budget-check` — this Makefile section's existing
on-demand targets — aren't mentioned in README.md either; `make
readme-check`'s own drift rule only fails when the README references a
nonexistent target, never the reverse). `make ci` must pass.

**ADR-0004 caveat:** this remote clusterless session ran the real sweep once
(30/30 real upstream repos resolved, 0 stale, ~39s) to prove the tool
actually functions end-to-end in the exact environment its intended invokers
(this repo's own routines) run in — that live run is not itself fabricated,
but it's also a point-in-time result, not re-asserted as still true at any
later date.

## PR

https://github.com/tooming/k8s-anywhere/pull/1375
