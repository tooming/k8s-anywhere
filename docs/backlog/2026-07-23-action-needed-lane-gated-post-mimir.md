# [Action needed] Now/next still gated post-Mimir bump; one upstream tag anomaly flagged, not taken

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments, `updated_at`
unchanged since 2026-07-21.

## What this cycle did

- **STEP 1b recovery:** none needed — no stale self-mergeable PRs from a
  prior run.
- **Upgrade-drafter lens → PR #665 (merged this cycle).** A fresh CVE/
  version sweep across every component *not* covered by the immediately
  preceding session's chart-pin sweep — `cert-manager` (1.21.0, current),
  `KEDA` (2.20.1, current — confirmed via Artifact Hub), `external-secrets`
  (chart 2.8.0, current — confirmed via real upstream git tags),
  `Kyverno` (chart 3.8.2 / appVersion 1.18.2 — cross-checked against every
  2026 GHSA advisory including the critical `CVE-2026-54523` published
  2026-07-13, already fixed at our exact pin), ArgoCD's own chart
  (bootstrapped via `infra/`, out of upgrade-drafter's file scope by
  design — noted, not actioned), HashiCorp Vault (unsealer image
  `2.0.3` — the three 2026 Vault CVEs found are all fixed at `2.0.0`,
  already covered), RabbitMQ (`4.3.3-management`, current — the two 2026
  CVEs found are fixed at `4.1.2`/`4.0.13` and `4.3.0`, both below our
  pin), Garage (`v2.3.0`, no newer tag, no CVE found) — found every pin
  already current or already patched, **except** `grafana/mimir` where
  `3.1.4` was a real, newer, verifiable stable patch (positively confirmed
  via Docker Hub's tags API and the real upstream `CHANGELOG.md`). Bumped
  it, `make ci` green (7/7 GitHub Actions checks; independently re-ran the
  full local bats suite too), self-reviewed, merged.
- **Longhorn `1.11.3` → `1.12.0` considered, correctly NOT taken.**
  ADR-0013's `## Re-evaluation log` records a deliberate 2026-07-18
  architect decision to stay one minor line behind `1.12.x` specifically
  because it GA'd the V2 Data Engine (a bigger behavioral-surface change
  than a routine currency bump warrants), with an explicit flip condition
  ("the `1.11.x` line itself approaches its own end-of-support window, or a
  specific CVE is filed") that has not fired. Bumping it this cycle would
  have **silently violated a binding ADR decision** — caught before
  building, not after; abandoned the branch without committing anything.

## This cycle's fresh angle — and one real anomaly found, not taken

Swept `grafana/loki` and `grafana/tempo` (the two observability-stack
plain-image pins the immediately preceding sessions' chart-pin sweep didn't
cover, since they're not Helm-chart-sourced). Tempo (`2.10.7`) has no newer
tag (`2.10.8`/`2.11.0` both 404). **Loki does — with a discrepancy worth
recording:**

- `grafana/loki:3.7.4` exists on Docker Hub (confirmed via the real tags
  API: `tag_last_pushed: 2026-07-22T06:07:40Z`, i.e. pushed yesterday
  relative to this session), one patch ahead of our current pin `3.7.3`.
- But **no `v3.7.4` git tag exists** in `github.com/grafana/loki` — `git
  ls-remote --tags` shows the line stops at `v3.7.3`; `v3.7.0`/`v3.7.1`/
  `v3.7.2`/`v3.7.3` are all present, `v3.7.4` is absent. The GitHub
  Releases page has no `v3.7.4` entry either (404). The upstream
  `CHANGELOG.md` on `main` has no `3.7.4` section (it jumps from the
  `3.8.0` minor, dated 2026-06-08, straight down to `3.7.1`).
- Per ADR-0004 and upgrade-drafter's own STEP 6 requirement ("Upstream
  notes: link to the release / changelog" — real, not invented), I cannot
  honestly document what changed in an image that has no corresponding
  source release. **Did not bump.** This may be an automated base-image
  security rebuild that doesn't cut a new git tag (a legitimate pattern
  some projects use) — but that's a guess, not a verified fact, so it
  doesn't clear the bar for an executor-authored version bump. Left the
  pin at `3.7.3`, unlike Mimir's `3.1.4` where a real, fetchable changelog
  entry existed.

**Flip condition for a future pass:** either a real `v3.7.4` (or later) git
tag / GitHub Release appears with actual release notes, or a CVE is filed
against `3.7.3` — at that point the case for bumping is verifiable in the
way this one currently isn't.

## Other lenses swept this cycle (also empty)

- **Planner:** no ungroomed issues beyond the three standing trackers;
  `docs/roadmap/incoming/` empty.
- **Architect:** `docs/roadmap/incoming/` empty — nothing queued for
  absorption. No new upstream CVE/release found firing an existing ADR's
  documented flip condition (Longhorn's is explicitly not fired; no other
  ADR carries an open flip condition as of this cycle).
- **Doc-drift:** `make ci`'s `readme-check`/`lab-ui-check`/
  `markdown-links-check` all clean — no drift signal to reconcile.
- **Triager:** all three open issues (#631/#632/#633) already fully
  labeled; no untriaged issues exist.
- **Janitor:** considered `tests/drift-detectors.bats` (662 lines, the
  largest bats file without a "frozen, split into per-scope files" guard
  unlike `observability.bats`/`securitycontext.bats`/`networkpolicy.bats`)
  as a candidate "shared monolith" cleanup. Declined: unlike those three
  files, there's no recorded evidence of merge-conflict pain on this file
  (each section is scoped to one drift-check script, added once per new
  script, which is organized growth rather than a proven footgun) — per
  CLAUDE.md's "never fabricate make-work," a large-file refactor with no
  concrete recurring-pain evidence isn't a justified cleanup on its own.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked flip
condition (Longhorn's, or a newly-discovered one); (c) `grafana/loki`
`3.7.4` (or later) getting a real, verifiable git tag/release; (d) a new
GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
