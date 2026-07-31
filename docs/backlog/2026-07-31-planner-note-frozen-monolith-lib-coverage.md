# Planner note — 2026-07-31 — backlog refill via gap-analysis sweep

## Why this run

The executor's STEP 1-3 orientation found ROADMAP.md's *Now / next* lane fully
starved: all three remaining unchecked `[ ]` items are gated —

- `verifyImages ClusterPolicy — Audit → Enforce flip` on
  [#631](https://github.com/tooming/k8s-anywhere/issues/631)
- `O4 CI gate — verify-image-rejection job` on the item above merging first
- `Remove legacy capstone Deployment` on
  [#633](https://github.com/tooming/k8s-anywhere/issues/633)

Both #631 and #633 were checked directly this run (issue comment threads
fetched via the GitHub API, not assumed): neither has a confirmation comment
from the maintainer yet — both still describe investigation-in-progress state
from 2026-07-29/30 sessions, with the underlying asks (a real CI run signing
and pushing an image; a real Kargo promotion observed end-to-end) still
outstanding. `gitops/kyverno/policies/verify-image-signatures.yaml` still
reads `validationFailureAction: Audit` / `failurePolicy: Ignore`, confirming
the gate is accurate and not just stale bookkeeping.

Per `executor.prompt.md` STEP 6b, an empty 🟢 lane escalates through the
fallback role chain starting with the planner. This is that planner pass.

## Gap-analysis sweep

Ran a five-angle sweep (delegated to a research pass, findings verified):
namespace NP/PSS coverage vs CHARTER O2, dashboard coverage vs O5, stateful
namespace Velero schedules vs O3, ADR chart/image pins vs their own
Re-evaluation log entries, and doc/make-target/script-path cross-reference
validity. Four of the five came back clean — this repo's own drift gates
(`dashboard-coverage.bats`, the per-namespace NP/PSS bats files, the
ADR chart/image-pin sync checks already in `make ci`) are doing their job.

The one real, concrete, mechanically-verifiable gap found: of the four shared
`scripts/lib/*.sh` helpers extracted from repeated copy-paste
(`colors.sh`, `hook-payload.sh`, `yq-variant.sh`, `budget-check.sh`), three
have a dedicated `tests/<name>-lib.bats` file exercising them directly —
`frozen-monolith-check.sh` and `frozen-monolith-sync-hook.sh` are the only
two lib files with no direct unit coverage, only transitive coverage through
the four wrapper scripts they back. Not a functional bug, but the one
extraction that skipped its own direct-unit-test half.

A second candidate — ADR-0016 (default-deny NetworkPolicy) has the oldest
`Re-evaluation log` entry of any ADR in the repo (2026-07-18, 13 days stale
as of this run) — was **not** groomed into a ROADMAP item here: that's an
architect-role ADR audit (`architect.prompt.md` STEP 2b), not planner-owned
grooming. If the backlog starves again before an architect cycle picks it up
naturally, a future executor run's fallback chain will reach the architect
role directly.

## What this PR does

Adds one new 🟢 item to *Now / next*, ahead of the three gated items so it's
immediately pickable next cycle: `tests/frozen-monolith-lib.bats` — direct
unit coverage for `scripts/lib/frozen-monolith-check.sh` +
`frozen-monolith-sync-hook.sh`, mirroring `hook-payload-lib.bats`'s shape,
plus a recurrence guard so a future fifth lib extraction can't silently skip
this again. No 🟡 items were groomed this run (none exist without an RFC —
verified against ROADMAP.md's history section, every 🟡 there is already
struck through as groomed). No open issues needed grooming — the only two
open issues are the standing #631/#633 confirmation trackers, not intake
work requests.

## PR

plan/frozen-monolith-lib-test-coverage
