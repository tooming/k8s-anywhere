# [Action needed] Now/next still fully gated; three real PRs landed first this run

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on a
**maintainer-confirmation prerequisite this remote clusterless session cannot
satisfy** (a live-cluster observation only the maintainer can make):

1. **verifyImages ClusterPolicy — Audit → Enforce flip** — needs confirmation
   on issue #631 that a CI run pushed a `.sig` tag to Artifactory.
2. **O4 CI gate — `verify-image-rejection` job** — depends on item 1 merging
   first.
3. **Capstone pipeline re-wire — Artifactory → Harbor** — needs confirmation
   on issue #632 that the minimal Harbor profile fits the 12 GB budget
   (measured on the live cluster).
4. **Decommission Artifactory manifests** — depends on item 3 merging first.
5. **Remove legacy capstone `Deployment`** — needs confirmation on issue #633
   that an Argo Rollouts canary + Kargo promotion ran end-to-end on the live
   cluster.

Re-verified this cycle: all three issues (#631/#632/#633) are still open with
zero comments — no confirmation posted since they were filed 2026-07-20.

## What this run did instead (3 real PRs, 1 labeling pass, before this note)

Worked the STEP 6b fallback chain from a cold start (fresh session, main was
locally stale and had to be reset to `origin/main` before anything else):

- **Planner lens:** no ungroomed issues (only the 3 standing `[Action
  required]` trackers above existed), `docs/roadmap/incoming/` empty, no
  unchecked ROADMAP items outside the gated five. Cross-checked ADR-0017's
  per-namespace profile table against every actual `gitops/*/namespace.yaml`
  in the repo — complete, no gaps. Spot-verified O2/O6/O7 objective artifacts
  (`dora-metrics.sh`, `capstone-demo.sh`, the PSS table) are present and
  wired. Nothing new to groom.
- **Architect lens:** no open `adr-audit` issues, no un-RFC'd 🟡 items (every
  🟡 in ROADMAP's Future section is already struck through/resolved). Ran a
  fresh upstream-release sweep across all 19 ADR-pinned components (releases
  in the last 7 days) — this is what surfaced the one real finding below.
- **Upgrade-drafter lens → PR #636:** `rabbitmq/rabbitmq-server` cut `v4.3.3`
  on 2026-07-20 (a Ra leader-election bug fix + `ra` dependency bump), one
  day after the prior run's exhaustive sweep. Bumped
  `gitops/data/rabbitmq/statefulset.yaml`'s image tag
  `4.3.2-management` → `4.3.3-management`, kept ADR-0009's inline pin mention
  + Re-evaluation log in sync, added bats coverage. Merged.
- **Triager lens:** the three standing `[Action required]` issues
  (#631/#632/#633) had zero labels. Labeled all three
  (`domain:bootstrap`/`domain:apps`, `readiness:green`, `priority:p1` — they
  block a current Now/next item, hence p1).
- **Janitor lens → PR #637:** `scripts/adr-chart-version-sync-check.sh`
  guards ADRs that self-track a Helm chart's `targetRevision`, but had no
  coverage for ADR-0009's inline plain-image-tag pin (the pattern PR #636
  above touches) — a guard with a known hole, a real recurrence-guard gap per
  CLAUDE.md's bugfix-prevents-recurrence rule. Added
  `scripts/adr-image-pin-sync-check.sh` + wired it into `make ci` +
  `.github/workflows/ci.yml` + the existing PostToolUse hook + fixture-backed
  bats coverage. Merged.
- **Doc-drift lens:** `make ci`'s `readme-check` and `lab-ui-check` are clean
  (verified in two full local `make ci` runs, before and after this run's own
  changes); no broken ArgoCD `Application` source paths found.

## This cycle's sweep (found nothing new)

A fresh non-ADR image-tag pass (`redis_exporter`, `apache/kafka`,
`motoserver/moto`, `hashicorp/vault` unsealer, `dxflrs/garage`,
`grafana/loki`, `grafana/mimir`, `grafana/tempo`) against live Docker Hub tag
data found every pin still at its latest real stable release as of
2026-07-21 — rabbitmq (already handled above) was the only genuine update in
this run. Grafana's own pin (`13.0.3`) is deliberately CVE-gated per
ADR-0006's Re-evaluation log (flip condition: a new bulletin naming
`>= 13.0.3` as affected) — a non-CVE minor release existing upstream
(`13.1.0`) does not meet that documented flip condition, so it was correctly
left alone, not bumped.

## What would unblock the gated lane

Any of: (a) the maintainer confirming a live-cluster observation on #631,
#632, or #633; (b) a new upstream CVE/release that fires one of the ADRs'
documented flip conditions (none found this cycle); (c) a new GitHub issue
describing further work of any size (the planner sizes it next cycle).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
