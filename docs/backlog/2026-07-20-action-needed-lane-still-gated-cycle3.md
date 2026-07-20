# [Action needed] Now/next still fully gated after 2 fresh real PRs this cycle

## What's blocked

Same as the immediately-prior run's own note
([`2026-07-20-action-needed-lane-fully-gated-and-swept.md`](2026-07-20-action-needed-lane-fully-gated-and-swept.md)):
the five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on a
maintainer-confirmation prerequisite this remote clusterless session cannot
satisfy (live-cluster state a human must observe and confirm) or a
merge-order dependency on one of those same items. None has a live-state-safe
slice left to split out per ROADMAP rule #9 — re-verified this run, same
conclusion as every prior pass.

## What this run already did instead (2 real merged PRs, before this note)

Rather than stop at the gated lane, this run worked the STEP 6b fallback
chain across two full cycles and landed real work each time:

- **Cycle 1 (planner → janitor fallback):** a fresh planner-style
  gap-analysis sweep across six areas (ADR re-evaluation staleness, O5
  dashboard coverage, O2 NetworkPolicy/PSS coverage, chart-version drift,
  missing bats coverage, `docs/dependency-tree.md` drift) found nothing new —
  matching the immediately-prior run's own exhaustive architect/
  upgrade-drafter-style sweep minutes earlier. Fell through to janitor,
  which found a real, previously-unguarded footgun: ADR-0020/ADR-0021's
  self-tracking "Chart + version" notes had already gone stale once
  (PR #616 fixed it manually) with no mechanical guard against a repeat.
  **PR #622** added `scripts/adr-chart-version-sync-check.sh` (+ make
  target, CI step, PostToolUse hook, bats coverage) closing that gap
  permanently. Merged.
- **Cycle 2 (upgrade-drafter fallback, different lens):** the
  immediately-prior run's chart-pin sweep only covered Helm-chart
  `Application` `targetRevision` pins via `git ls-remote`. This cycle swept
  every **standalone container-image pin** on a plain manifest instead (a
  lens that sweep never touched): `rabbitmq:4.3.2-management` (current),
  `curlimages/curl:8.21.0` (current), `dxflrs/garage:v2.3.0` (current — the
  highest real semver tag on Docker Hub, verified directly), `valkey/valkey:
  8.0-alpine` (correctly **left alone** — ADR-0018 §"Plain manifests over a
  Helm chart" explicitly pins this exact tag as its binding decision, so
  bumping it needs an architect RFC, not an upgrade-drafter PR),
  `cloudlena/s3manager:latest` and `jaegertracing/example-hotrod:latest`
  (both intentionally on the floating `:latest` tag, out of scope by the
  routine's own rule). Found one real, current gap:
  `oliver006/redis_exporter:v1.84.0-alpine` was 3 patches behind
  `v1.87.0-alpine` (verified `tag_status: active`, multi-arch, real digest
  via Docker Hub's tags API). **PR #623** bumped it + added a recurrence-guard
  bats assertion. Merged.

## This cycle's sweep (found nothing new)

A third pass, deliberately using yet another lens: janitor's other two
categories (duplication, dead/stale matter). Found nothing that clears the
"real, already-bitten footgun" or "meaningfully near-identical logic" bar —
the one duplication candidate surfaced (9 scripts each define their own
2-line inline `ok()`/`bad()` printf helper) is long-standing, extremely
lightweight, already-tolerated repo convention, not a bug class that has
ever actually recurred; extracting it would be a 9-file refactor for
near-zero risk reduction, which reads as manufactured churn, not a genuine
fix — per CLAUDE.md, fabricated make-work is forbidden even to avoid this
outcome. No TODO/FIXME/XXX markers exist anywhere in `scripts/` or `gitops/`
(checked directly). Zero open GitHub issues (triager's lane: nothing to
label). `make ci` clean (doc-drift's lane: no readme-check/lab-ui-check
signal, confirmed fresh after both of this run's merges).

## What would unblock the gated lane

Unchanged from the prior note: (a) the maintainer confirming a live-cluster
observation for the verifyImages-Enforce-flip or Harbor-cutover items; (b) a
new upstream CVE/release firing one of the ADRs' flip conditions (none found
across two independent sweeps today); (c) a new GitHub issue describing
further work of any size, or a new architect RFC (e.g. authorizing a Valkey
`8.0-alpine` → `8.1-alpine` minor bump, currently correctly blocked by
ADR-0018's binding pin).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
