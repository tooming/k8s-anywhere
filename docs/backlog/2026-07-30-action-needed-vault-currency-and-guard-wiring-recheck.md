# [Action needed] Now/next still gated; Vault chart/image currency + docs-done guard wiring re-verified

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items
(`verifyImages ClusterPolicy — Audit → Enforce flip`, `O4 CI gate —
verify-image-rejection job`, `Remove legacy capstone Deployment`) — all
gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633). Re-checked this
cycle: both still open, no new comments since 2026-07-29T22:10 UTC (#631)
and 2026-07-29T16:30 UTC (#633) — genuinely unresolved, not stale trackers.
No live-cluster-safe slice of either gated item exists to split off (both
are atomic enforcement/removal flips per rule #9's split-the-gate test).

## STEP 6b fallback chain walked this cycle

- **Planner lens:** `gh issue list --state open` returns exactly the same 2
  standing `[Action required]` issues (#631, #633) — no ungroomed intake, no
  `rfc`-labeled issues, `docs/roadmap/incoming/` empty (only its README).
  Zero live `- [ ] 🟡` lines in ROADMAP.md — nothing un-RFC'd to block on.
- **Architect lens:** no open `adr-audit` issues; no 🟡 item pending a
  decision.
- **Upgrade-drafter lens (fresh technique):** picked a component not named
  in yesterday's chart-currency sweeps — Vault. `gitops/platform/vault.yaml`
  pins Helm chart `0.34.0` (`https://helm.releases.hashicorp.com`, blocked
  from this sandbox — proxy returns 403 on CONNECT, confirmed via
  `$HTTPS_PROXY/__agentproxy/status`). Verified via `git ls-remote --tags`
  against the chart's real GitHub source (`hashicorp/vault-helm`, git
  protocol, unblocked): `v0.34.0` is the newest tag in the repo — pin
  current. Vault server image tag `2.0.3`: fetched
  `raw.githubusercontent.com/hashicorp/vault/main/CHANGELOG.md` live —
  `2.0.3` (June 17, 2026) is the topmost/newest entry, no version above it
  exists. **Both current, no bump available.** (Vault was last
  independently audited 2026-07-24/2026-07-29 with the same conclusion —
  this cycle re-confirms via a distinct verification path: chart via
  git-protocol tag listing rather than the blocked `index.yaml`, image via a
  direct live CHANGELOG fetch rather than citing the prior audit.)
- **Doc-drift lens:** `make ci` run in full this cycle — 100% green
  (`readme-check`, `lab-ui-check`, `markdown-links-check`,
  `docs-done-pr-link-check`, every ADR/context.md version-sync check, the
  `ci-parity-check` confirming `make ci` and `.github/workflows/ci.yml` run
  the identical gate set).
- **Triager lens:** both open issues already carry `priority:*`,
  `readiness:*`, and `domain:*` labels — nothing to triage.
- **Janitor lens (fresh technique):** the previous cycle's PR
  ([#890](https://github.com/tooming/k8s-anywhere/pull/890)) claimed a new
  recurrence guard (`scripts/docs-done-pr-link-check.sh` +
  `docs-done-pr-link-sync-hook.sh`) was wired into `make ci`, the GitHub
  Actions parity set, and a `PostToolUse` hook. Rather than trust the PR
  body, verified independently this cycle (ADR-0004 — verify before
  asserting, applied to a prior *agent's* claim, not just the lab's
  runtime state): both scripts exist and are executable; `Makefile` invokes
  `docs-done-pr-link-check.sh` from both the standalone target (line 151-152)
  and the `ci` target's script list (line 205); `.claude/settings.json`'s
  `PostToolUse` hooks array invokes `docs-done-pr-link-sync-hook.sh` on
  save; `tests/docs-done-pr-link-check.bats` exists. **Claim confirmed
  accurate — fully wired, no follow-up needed.**

## What this cycle already did

No merges — the fallback chain (above) came back clean at every stop, and
no new gap qualified as a real, bounded janitor cleanup (the one candidate
inspected — verifying #890's guard wiring — checked out clean rather than
surfacing a defect to fix).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 (a real CI run
signing + pushing to Harbor) or #633 (a real Kargo promotion observed); (b)
a new GitHub issue of any size (ungroomed intake); (c) a new upstream
CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record — two genuinely fresh angles (a
distinct Vault currency verification path, and an independent recheck of
the immediately-prior cycle's own guard-wiring claim) that both came back
clean, not a repeat of a check already logged. The run continues to the
next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
