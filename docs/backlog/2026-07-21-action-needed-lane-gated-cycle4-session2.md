# [Action needed] Now/next still fully gated; three real PRs landed this session, fourth-cycle sweep found nothing further

## What's blocked

Unchanged from every prior cycle today: the five remaining `[ ]` items in
ROADMAP.md's *Now / next* are all gated on the standing maintainer-confirmation
issues #631/#632/#633 — re-verified this cycle, all three still open, still
zero comments.

## What this session did

This session (starting from a stale local `main` that needed a hard reset to
`origin/main` due to a shallow-clone artifact — no shared history boundary
within the fetch depth) landed three real, `make ci`-green, self-reviewed and
self-merged PRs:

- **#648** — `chore/capstone-securitycontext-path-aware-tests`: converted the
  last remaining bare-`grep -q` `securityContext` assertions in the FROZEN
  `tests/securitycontext.bats` monolith (the capstone Deployment block) to
  path-aware `yqs()` reads, completing the recurrence-guard hardening sweep
  started with vault (#541) and continued with moto/ack-s3/kro (#542). A
  repo-wide check confirmed every other `tests/securitycontext-<scope>.bats`
  file only asserts flat PSA labels / Application shape (no nested-key
  ambiguity), so nothing else needed converting.
- **#649** — `chore/ci-workflow-job-timeouts`: added explicit `timeout-minutes`
  to all six `.github/workflows/ci.yml` jobs plus a `drift-detectors.bats`
  recurrence guard, directly motivated by landing #648 itself — the `unit`/
  `drift` jobs sat `in_progress` for 20+ minutes with zero progress across
  three separate attempts (an external network/infra flake on the install
  steps), and without an explicit timeout GitHub Actions' 360-minute default
  would have let a genuine hang block a PR for hours with no automatic
  recovery.
- **#650** — `upgrade/pyroscope-2.1.1-to-2.1.2`: the upgrade-drafter fallback
  lens (not yet tried this specific session) found three non-CVE candidate
  chart bumps from a fresh sweep of every non-ADR-pinned Helm chart in
  `gitops/` (pyroscope patch, grafana patch, alloy minor). Picked pyroscope as
  the lowest-risk of the three — grafana's chart `targetRevision` has a
  deliberate recent-history precedent of being left untouched during CVE work
  (`docs/done/2026-07-19-grafana-cve-bump-13-0-3.md`), so an opportunistic
  version-only bump there was held back this cycle.

## This cycle's fresh sweep (came up empty)

- **Planner/architect/doc-drift/triager lenses:** re-checked, all still clean
  — no ungroomed issues, `docs/roadmap/incoming/` empty, no un-RFC'd 🟡 items,
  `make ci`'s `readme-check`/`lab-ui-check`/`markdown-links-check` all clean,
  no broken ArgoCD `Application` source paths (scripted check across every
  `gitops/**/*.yaml` `path:` reference), only the three standing `[Action
  required]` issues open (all correctly labeled, nothing untriaged).
- **Janitor lens, second pass — securitycontext yqs() sweep, take 2:**
  re-checked every `tests/securitycontext-<scope>.bats` file for actual
  nested-key `securityContext` field assertions (not just PSA-label/
  Application-shape ones) — confirmed none exist outside what #648 already
  fixed; the sweep is genuinely complete now, not just "nothing found this
  pass."
- **Janitor lens, second pass — shell strict-mode audit:** checked every
  `scripts/*.sh` for its `set -...` flags; found a consistent two-way split
  (62 files `set -uo pipefail`, 14 files `set -euo pipefail`) that initially
  looked like unintentional drift. On inspection this is deliberate: check/
  drift-detector scripts intentionally omit `-e` so a `grep -q` returning
  non-zero (an expected "check failed" signal, not a script-fatal error)
  doesn't abort the script before it can report every failure; bootstrap/
  mutation scripts use `-e` so any single command failing halts immediately.
  Not a bug — correctly left alone rather than "fixed" into a regression.
- **Observability test file:** checked `tests/observability.bats` (the other
  FROZEN monolith, 569 lines) for the same bare-grep securityContext
  key-mismatch pattern #648 fixed — it has zero `securityContext`-related
  assertions at all (different domain: dashboards/scrape configs), so the bug
  class doesn't apply there.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on #631,
#632, or #633; (b) a new upstream CVE/release firing one of the tracked ADRs'
documented flip conditions; (c) a new GitHub issue of any size (the planner
sizes it next cycle).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
