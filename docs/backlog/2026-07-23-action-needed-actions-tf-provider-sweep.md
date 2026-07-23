# [Action needed] Now/next still gated; GitHub Actions pin + Terraform provider sweep found nothing actionable

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, still zero comments, `updated_at` unchanged
since 2026-07-21.

## What this cycle did

- **STEP 1b recovery:** none needed — no open PRs at all when this cycle
  started (the immediately preceding cycle's `[Action needed]` PR, #666, had
  already merged).
- **Local checkout repair:** this session's local `main` ref was stale
  (pointed at old commit `070619e`, ~200 commits behind `origin/main`'s
  `fc72df2`), diverged rather than fast-forwardable. Reset the local branch
  pointer to `origin/main` (`git checkout -B main origin/main`) — a safe
  local-ref move, no data at risk (working tree was clean, nothing pushed
  from the stale state).
- **make ci:** green locally (drift/lint/doc checks; heavier tools
  unavailable in this sandbox). Cross-checked the real GitHub Actions `ci.yml`
  run for `origin/main`'s HEAD (`fc72df24`, run 29970607865): `completed` /
  `success`. No CI breakage to fix.

## This cycle's fresh angle — two lenses not seen in prior notes today

1. **GitHub Actions pin format audit.** Checked every `uses:` line across all
   six `.github/workflows/*.yml` files for the classic supply-chain gap
   (actions pinned to a mutable tag/branch instead of an immutable commit
   SHA). Result: **already fully SHA-pinned** — `actions/checkout`,
   `actions/cache`, `actions/github-script`, `hashicorp/setup-terraform` all
   reference a full 40-char SHA with a `# vX.Y.Z` comment for readability.
   Nothing to fix; this ROADMAP work (the struck-through "GitHub Actions
   major-version bumps" item, `docs/backlog/`) already covered it.
2. **Terraform provider version-constraint audit.** Checked
   `required_providers` blocks across every `infra/modules/*/main.tf` for
   floating/unconstrained versions. Result: every provider (`hashicorp/helm`,
   `oracle/oci`, `hashicorp/null`, `hashicorp/local`, `gitlabhq/gitlab`,
   `hashicorp/kubernetes`) uses a `~>` pessimistic-constraint pin (e.g.
   `~> 2.17`, `~> 7.0`) — the idiomatic Terraform pattern for provider
   version ranges, distinct from this repo's exact-tag convention for
   container images/Helm charts (which need exact reproducibility; providers
   get patch-level auto-updates by design). Not a gap — no change proposed.
3. **k3s CVE re-check.** Re-searched for any k3s security advisory newer than
   CVE-2026-54250 (the one that drove the `v1.36.2+k3s1` pin, already merged
   via `auto/k3s-version-pin`). Found only the same CVE, already fixed at our
   pin. No new k3s advisory exists as of this cycle.

## Other lenses swept this cycle (also empty)

- **Planner:** no open issues beyond the three standing `[Action required]`
  trackers (#631/#632/#633); `docs/roadmap/incoming/` empty (only its
  `README.md`). No gap analysis finding — CHARTER's Objectives (O1–O7) are
  either met, not yet due (O3/O6: 2026-12-31; O7: 2026-10-31), or blocked on
  the same tracked gates (O4).
- **Architect:** every 🟡 item in ROADMAP.md's "Groomed / resolved" history is
  struck through — none pending an RFC. Every ADR `## Re-evaluation log` flip
  condition checked in the immediately preceding cycles (Longhorn,
  kube-state-metrics, envoy-gateway-system PSS, artifactory PSS, inkless PSS)
  is unchanged: none fired.
- **Upgrade-drafter:** the immediately preceding cycle
  (`docs/backlog/2026-07-23-action-needed-lane-gated-post-mimir.md`) ran a
  comprehensive sweep across every chart/image pin in `gitops/` minutes
  before this one started; re-running the identical sweep this soon would be
  pure repetition, not a fresh angle — deferred to a future cycle once real
  time has passed upstream.
- **Doc-drift:** `make ci`'s `readme-check` / `lab-ui-check` /
  `markdown-links-check` / ADR chart-version-sync / ADR image-pin-sync checks
  are all clean.
- **Triager:** all three open issues already fully labeled
  (`priority:p1`, a `domain:*` label, `readiness:green`).
- **Janitor:** no new untested script or undocumented Makefile target found;
  every `scripts/*.sh` already has bats coverage per the immediately
  preceding cycles' sweep.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked ADR
flip condition; (c) a new GitHub issue of any size; (d) enough wall-clock
time passing for another upgrade-drafter chart/image sweep to find fresh
upstream movement.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
