# Planner run — 2026-07-16 — hook-scripts negative-path coverage

## What triggered this run

This was the executor routine reaching the planner role via the STEP 6b fallback
chain. The "Now / next" lane was fully starved — all six remaining unchecked items
were gated:

- `verifyImages ClusterPolicy — Audit → Enforce flip` — blocked on `auto/cosign-ci-sign-step`
  merging AND a live-cluster `.sig` tag confirmation, neither verifiable remotely.
- `O4 CI gate — verify-image-rejection job` — blocked on the enforce-flip item above.
- `Capstone pipeline re-wire — Artifactory → Harbor` — blocked on a maintainer
  confirmation that the Harbor footprint fits the 12 GB budget on the live cluster.
- `Decommission Artifactory manifests` — blocked on the Harbor re-wire item above.
- `Remove legacy capstone Deployment` — blocked on a maintainer confirmation that the
  Argo Rollouts canary pipeline was exercised end-to-end (a live Kargo promotion) on
  the real cluster.
- `ADR-0017 audit — vault PSA-restricted` (🟡) — explicitly marked "the executor skips
  this item" until the upstream Vault Helm chart drops `cap_ipc_lock`; not architect
  work, no RFC to write.

No open PRs, no open issues (nothing to groom via intake), and no pending
`docs/roadmap/incoming/` files from the architect. The "Cross-cutting hardening &
quality" section had nothing left to promote either — every entry there is already
struck through as groomed into Now/next, except the same vault 🟡 item above.

## Gap analysis

- **O2** (default-deny + PSS-restricted): `tests/networkpolicy.bats` already carries a
  live drift guard asserting every NP-overlay namespace has its own bats file — no
  uncovered namespace found.
- **O5** (every always-on component has a dashboard): `tests/dashboard-coverage.bats`
  already exhaustively enumerates every `automated: true` Application in
  `gitops/platform/*.yaml` against `grafana/dashboards/`; cross-checked all ~40 —
  nothing missing.
- **ADR-0017 vault carve-out**: re-evaluated and logged 2026-06-11 (issue #157); not
  stale.
- **Coverage/hardening sweep**: found a real, already-flagged gap. The most recent
  merged PR (`docs/done/2026-07-16-hook-scripts-bats-coverage.md`, itself a prior
  janitor fallback run) closed bats coverage for 13 previously-untested hook scripts
  but explicitly left `argocd-crd-ssa-sync-hook.sh` and `helm-chart-pin-sync-hook.sh`
  with only filter + real-repo happy-path coverage, no negative (drift-detected) path,
  citing their underlying checks as "network-tolerant with no hook-level file-scoped
  override for injecting a broken fixture" — named as "a reasonable following janitor
  pickup."

  That note undersells what's actually available: both underlying `*-check.sh` scripts
  already have offline test seams (`CHARTPINCHECK_ROOT`/`CHARTPIN_RESOLVER` and
  `CRDSSA_CHECK_ROOT`/`CRDSSA_RENDERER`) with fixtures already checked in
  (`tests/fixtures/helm-chart-pin/`, `tests/fixtures/argocd-crd-ssa/`) and already
  exercised by `tests/drift-detectors.bats`. Since each hook script `bash`-invokes its
  check script in the same shell (no `env -i`), the same stub env vars propagate
  straight through the hook. No new fixtures needed — just two more `@test` cases in
  `tests/hook-scripts-coverage.bats`. Verified this directly by reading both hook
  scripts, both check scripts, and both fixture trees before adding the item.

## Groomed into

One 🟢 ROADMAP item, no prerequisites, appended to the end of Now/next (after the
last existing unchecked item, before "Heavy on-demand components"):
`auto/hook-scripts-negative-path-coverage`.

## Lane health after this plan PR merges

The six previously-gated items remain gated (nothing here unblocks them — they
genuinely need a maintainer's live-cluster confirmation or another PR to merge
first). The new item is immediately buildable and clusterless, so the next executor
run has real 🟢 work without needing to fall through the chain again.
