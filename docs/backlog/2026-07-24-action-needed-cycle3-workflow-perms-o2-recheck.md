# [Action needed] Now/next still gated; workflow job-perms + O2 table re-check clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (third cycle of 2026-07-24): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

Two checks not covered by cycle 1
(`docs/backlog/2026-07-24-action-needed-cycle1-workflow-adr-sweep.md`,
which checked `uses:` SHA-pinning + top-level `permissions:` presence) or
cycle 2 (`docs/backlog/2026-07-24-action-needed-cycle2-chart-pin-verification.md`,
which checked External Secrets Operator / Trivy Operator / KEDA chart pins):

1. **GitHub Actions job-level `permissions:` scoping.** Cycle 1 confirmed all
   7 workflows declare a `permissions:` block; this cycle checked *what* each
   block actually grants, looking for over-privileged defaults a job doesn't
   need. Result: `ci.yml` / `oracle-cluster-apply(-retry).yml` /
   `pr-up-to-date.yml` grant only `contents: read`; `auto-update-prs.yml`
   grants `contents: write` + `pull-requests: read` (needed — it rebases and
   pushes PR branches); `close-idle-on-delivery.yml` grants only
   `issues: write`; `delete-closed-pr-branch.yml` grants only
   `contents: write`. Every grant matches what its job actually does — no
   over-privileged default found. No gap.
2. **ADR-0017 §Per-namespace profile table vs. actual `gitops/**/namespace.yaml`
   coverage — re-verified.** Enumerated all 28 `namespace.yaml` files under
   `gitops/` via `find gitops -name namespace.yaml` and cross-checked each
   declared namespace against ADR-0017's table by name (not by a naive
   column-position grep, which false-positived on profile-value cells like
   `baseline`/`restricted` in an earlier pass this cycle before the mistake
   was caught and corrected — worth noting since it could mislead a future
   sweep the same way). Confirmed present, including the less-obviously-named
   rows: `storage` (Garage), `tidb`/`tidb-admin`, `moto`/`ack-system`. Matches
   `docs/backlog/2026-07-23-action-needed-cycle4-o2-coverage-audit.md`'s
   finding — still fully covered, no new namespace added since. No gap.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
