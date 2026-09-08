# [Action needed] Cycle 26 — CI-workflow-safety lens now exhausted

Follow-up to cycles 17/18
([2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md](2026-09-08-action-needed-cycle17-doc-drift-sweep-exhausted.md),
[2026-09-08-action-needed-cycle18-infra-ci-currency-clean.md](2026-09-08-action-needed-cycle18-infra-ci-currency-clean.md)).
This run has landed 6 more merged PRs since cycle 18 (#1533–#1538,
cycles 20–25): an on-demand DORA-metrics snapshot refresh, a stale
namespace-count doc fix, two ROADMAP legacy-item-trim batches, and — the
richest vein this cycle — a CI-workflow-concurrency-safety sweep that
found and fixed two real gaps (`oracle-cluster-apply.yml` +
`oracle-cluster-apply-retry.yml` sharing unlocked Terraform state with no
serialization, #1537; `auto-update-prs.yml` overlapping on rapid
same-session pushes, #1538). This cycle finished sweeping that lens to
completion and found no further gap.

## What this cycle checked (all came up clean)

- **Every remaining `.github/workflows/*.yml` file** for the same
  missing-concurrency-group class: `pr-up-to-date.yml` (fires on every PR
  push, but the job itself runs in seconds — no meaningful overlap-vs-cost
  case the way `ci.yml`'s ~3-minute bats job had); `delete-closed-pr-branch.yml`
  (each invocation operates on a distinct, PR-specific branch ref with no
  shared mutable state between different closed PRs — nothing to
  serialize). Both assessed and correctly left alone.
- **Executable-bit consistency across `scripts/*.sh`**: found 9 scripts
  without the executable bit (`argocd-crd-ssa-sync-hook.sh`,
  `check-merged-pr-push.sh`, `git-fixture-isolation-check.sh`,
  `ok-bad-lib-check.sh`, `ok-bad-lib-sync-hook.sh`,
  `prune-stale-branches.sh`, `roadmap-sync-hook.sh`, `yqs-lib-check.sh`,
  `yqs-lib-sync-hook.sh`) against the rest being `+x`. Confirmed this is
  cosmetic, not a functional bug: every one of these (and every other
  script in the repo) is invoked exclusively as `bash scripts/<name>.sh` —
  never `./scripts/<name>.sh` — from the `Makefile`, `.claude/settings.json`
  PostToolUse hooks, and `.githooks/pre-push`, so the executable bit is
  never actually read. Not worth a PR on its own (pure inconsistency, zero
  behavior change either way).
- **Orphan/dead-script sweep** (`check-merged-pr-push.sh` specifically —
  it looked unreferenced by a naive `grep` for files ending in
  `.githooks/*` since those have no file extension): confirmed it is
  real, live-wired into `.githooks/pre-push` — already investigated and
  confirmed the same way by an earlier cycle
  ([2026-08-06-action-needed-post-second-janitor-sweep-clean.md](2026-08-06-action-needed-post-second-janitor-sweep-clean.md)),
  re-confirmed here rather than re-litigated from scratch.
- **`docs/dependency-register.md`'s "Last reviewed" freshness**: every row
  already mechanically guarded (`scripts/dependency-register-check.sh`,
  since 2026-08-24) and all green in this run's own `make ci` output —
  nothing stale to find manually here that the mechanical guard would have
  missed.

## What would open new work

- A new upstream release, CVE, or GitHub issue/RFC (none pending — 0 open
  issues, 0 open PRs as of this cycle).
- A future cycle finding a genuinely different angle (this run has now
  tried: removed-component leftover rationale, incident-log follow-ups,
  ADR flip-condition staleness, dependency currency, docs-vs-manifest
  cross-checks, infra/CI tooling currency, CI-workflow-configuration
  hygiene, on-demand generated-report currency, ROADMAP legacy-item
  trimming, and CI-workflow concurrency-safety — each swept to a clean or
  resolved state).
- Issue #1517 (coredns-host-alias vestigial-step removal) resolving — it
  remains gated on live-cluster verification this remote session cannot
  perform.

This is this cycle's honest record, per `executor.prompt.md` STEP 6b's
last resort. The run continues (STEP 8) — going back to STEP 1
immediately.
