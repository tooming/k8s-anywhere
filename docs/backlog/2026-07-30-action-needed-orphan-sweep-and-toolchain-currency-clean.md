# [Action needed] Now/next still gated; orphan-file sweep found + fixed a real bug, toolchain currency re-verified clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items
(`verifyImages ClusterPolicy — Audit → Enforce flip`, `O4 CI gate —
verify-image-rejection job`, `Remove legacy capstone Deployment`) — all gated
on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633). Re-checked this
cycle: both still open, no new comments since 2026-07-29/30. No
live-cluster-safe slice of either gated item exists to split off (rule #9's
split-the-gate test — both are atomic enforcement/removal flips).

## What this run already did

One real merged PR this run, via a **fresh janitor-lens angle** not yet
tried in any of today's/yesterday's extensive fallback sweeps: a repo-wide
kustomize orphan-file scan (every file sitting next to a `kustomization.yaml`
must actually be referenced by it). This found exactly one orphan across all
52 `kustomization.yaml` files in the repo:
`gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml` — dropped
from its kustomization's `resources:` list when the shared
`zz-dns-clusterip-bridge.yaml` template superseded it, but never deleted, and
still being edited as if live nearly a month later (PR #716). Fixed
(deleted the dead file, corrected the two stale `tests/harbor.bats`
assertions that had asserted its existence) and, per CLAUDE.md's
bugfix-must-prevent-recurrence rule, added a permanent mechanical guard:
`scripts/kustomize-orphan-check.sh` (+ `make kustomize-orphan-check`, CI
wiring, a PostToolUse sync-hook, and bats coverage) so the same class of bug
can't silently recur. Landed as
[#903](https://github.com/tooming/k8s-anywhere/pull/903).

## This cycle's fresh angles (all clean)

Re-entered the STEP 6b fallback chain for a second cycle this run. Planner
lens: `gh issue list --state open` still returns exactly the 2 standing
`[Action required]` issues, no ungroomed intake, no `rfc`-labeled issues,
`docs/roadmap/incoming/` empty. Architect lens: no un-RFC'd 🟡 item anywhere
in ROADMAP.md. Then four **structural sweeps distinct from every prior
sweep's shape** (prior sweeps checked chart/image currency, ADR re-eval
logs, securityContext key-nesting, doc drift, RFC follow-up — never these):

1. **Orphaned scripts.** Cross-referenced every `scripts/*.sh` against every
   `Makefile`/`.github/workflows/*.yml`/`.claude/settings.json`/other-script
   reference — zero scripts unreferenced anywhere.
2. **Orphaned test fixtures.** Cross-referenced every `tests/fixtures/*/`
   directory name against every `tests/*.bats` file — zero fixture
   directories unreferenced.
3. **Dangling script references.** Cross-referenced every
   `scripts/....sh` mention in `Makefile`/`.github/workflows/*.yml`/
   `.claude/settings.json` against the real filesystem — zero dangling
   references (the inverse check of #1).
4. **Toolchain currency, two lenses not yet checked today:** Terraform
   provider version constraints (`infra/**/*.tf`'s `required_providers`
   blocks: `hashicorp/helm ~> 3.0`, `gitlabhq/gitlab ~> 19.0`,
   `hashicorp/null ~> 3.2`, `hashicorp/local ~> 2.5`, `oracle/oci ~> 8.0`) —
   all are pessimistic (`~>`) range constraints already satisfied by their
   real latest upstream tags (`v3.2.0`, `v19.2.1`, `v8.25.0` respectively),
   so unlike a Helm chart's exact `targetRevision` pin, nothing needs
   bumping; and GitHub Actions pins in `.github/workflows/*.yml` (`actions/
   checkout@v7.0.1`, `actions/cache@v6.1.0`, `actions/github-script@v9.0.0`,
   `hashicorp/setup-terraform@v4.0.1`) — all four confirmed to already be
   the newest real tag on their upstream repo via `git ls-remote --tags`.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 (a real CI run
signing + pushing to Harbor) or #633 (a real Kargo promotion observed); (b) a
new GitHub issue of any size (ungroomed intake); (c) a new upstream
CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record — one real merged PR (a genuine
dead-code bug found and permanently guarded against recurrence) plus four
fresh, previously-untried sweep angles that all came back clean, not a
repeat of a check already logged. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
