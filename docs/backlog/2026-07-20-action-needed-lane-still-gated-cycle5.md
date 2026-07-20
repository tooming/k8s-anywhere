# [Action needed] Now/next still fully gated; every fallback lens now exhausted

## What's blocked

Unchanged from this run's prior notes: the five remaining `[ ]` items in
ROADMAP.md's *Now / next* are all gated on a maintainer-confirmation
prerequisite this remote clusterless session cannot satisfy, or a
merge-order dependency on one of those same items. Re-verified this cycle,
same conclusion as every prior pass this run.

## What this run has done across 4 cycles (3 real merged PRs)

- **Cycle 1 (planner → janitor):** fresh 6-area gap-analysis sweep found
  nothing new; janitor found and fixed a real, previously-unguarded
  footgun — **PR #622**, a mechanical guard against stale self-tracking
  ADR "Chart + version" notes (the exact bug class that bit ADR-0020 once
  already, via PR #616).
- **Cycle 2 (upgrade-drafter, standalone images, partial sweep):**
  `gitops/apps/`, `gitops/data/`, `gitops/storage/` checked. **PR #623**
  bumped `redis_exporter` v1.84.0 → v1.87.0.
- **Cycle 3 (janitor duplication/dead-code, triager, doc-drift):** all
  came up empty — recorded honestly as `[Action needed]` PR **#624**.
- **Cycle 4 (upgrade-drafter, standalone images, remaining directories):**
  `gitops/inkless/`, `gitops/moto/`, `gitops/observability/`,
  `gitops/vault/`, `gitops/tidb-demo/` checked. **PR #625** bumped
  `apache/kafka` 3.9.1 → 3.9.2. `kafka-exporter`, `moto`, `vault` (unsealer)
  all confirmed already current.

## This cycle's sweep: the standalone-image lens is now provably complete

Every `image:` reference across the **entire** `gitops/` tree (not a subset —
verified via `grep -rn '^\s*image:\s*[a-z]' gitops/` across every
subdirectory, 22 total references) has now been checked directly against
its real registry:

| Image | Pin | Status |
|---|---|---|
| `rabbitmq` | `4.3.2-management` | current |
| `valkey/valkey` | `8.0-alpine` | **ADR-0018-pinned — correctly left alone**, needs an architect RFC to bump |
| `oliver006/redis_exporter` | `v1.87.0-alpine` | current (bumped this run, #623) |
| `curlimages/curl` | `8.21.0` | current |
| `dxflrs/garage` | `v2.3.0` | current (highest real semver tag) |
| `cloudlena/s3manager` | `latest` | intentional floating tag, out of scope |
| `danielqsj/kafka-exporter` | `v1.9.0` | current |
| `ghcr.io/aiven/inkless` | `latest` | intentional floating tag, out of scope |
| `apache/kafka` | `3.9.2` | current (bumped this run, #625) |
| `postgres` | `17` | intentional floating major tag, out of scope |
| `motoserver/moto` | `5.2.2` | current |
| `grafana/loki` | `3.7.3` | current (direct tag probe: no 3.7.4/3.8.0 exists) |
| `grafana/mimir` | `3.1.3` | current (highest real semver tag) |
| `grafana/tempo` | `2.10.7` | current (direct tag probe: no 2.10.8/2.11.0 exists) |
| `docker.io/grafana/grafana` | `13.0.3` | current (bumped in an earlier run) |
| `hashicorp/vault` (unsealer) | `2.0.3` | current (highest 2.0.x patch) |
| `artifactory.../hello`, `jaegertracing/example-hotrod` | `latest` | intentional floating tags, out of scope |

Combined with the immediately-prior run's own exhaustive Helm-chart-pin
sweep (`git ls-remote --tags` against every real upstream chart repo) and
ADR flip-condition sweep, **every image and chart pin in this repo is now
directly verified against its real upstream registry as of 2026-07-20** —
there is no known further upgrade-drafter work available this run.

Also re-confirmed this cycle: zero open GitHub issues (triager), `make ci`
clean (doc-drift), no TODO/FIXME/XXX anywhere in `scripts/`/`gitops/`
(janitor — checked in cycle 3).

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation for the
verifyImages-Enforce-flip or Harbor-cutover items; (b) a new upstream
CVE/release (none found across this run's sweeps as of 2026-07-20); (c) a
new GitHub issue of any size; (d) an architect RFC authorizing the
ADR-0018-pinned Valkey bump (`8.0-alpine` → `8.1-alpine`, a minor bump
correctly out of upgrade-drafter's own reach).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
