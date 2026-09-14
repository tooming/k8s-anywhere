# [Action needed] Cycle 29 — k3s/ArgoCD/cert-manager currency re-check, clean

## This run so far

Twenty-seven PRs shipped this run (#1588–#1615). See prior
`docs/backlog/2026-09-14-*.md` files for each cycle's detail.

## This cycle

Re-checked the three most recently-touched live pins now that roughly two
hours of real time have passed since cycles 19–20 last verified them:

- **k3s**: `github.com/k3s-io/k3s/releases` still shows `v1.37.0+k3s1`
  (2026-09-14) as the newest stable tag — no `v1.37.1+` yet. PR #1607's
  flip condition ("revisit when `v1.37.1` or later ships") is not met.
  This repo's pin stays at `v1.36.4+k3s1`, unchanged.
- **ArgoCD**: `argo-helm`'s `releases.atom` still shows `argo-cd-10.9.1`
  (2026-09-14) as the newest chart release — matches this repo's pin from
  PR #1606. No bump due.
- **cert-manager**: `cert-manager/releases.atom` still shows `v1.21.2`
  (2026-09-11) as the newest release — matches this repo's pin. No bump
  due.

All three unchanged since this run's own last check. No new work.

## Assessment

Twenty-nine consecutive cycles this run have worked the fallback chain.
This cycle demonstrates the currency-sweep angle genuinely does exhaust
itself on a short timescale — nothing upstream has moved in the ~2 hours
since cycles 19–20 last checked these same three pins, confirming those
cycles' own findings rather than surfacing anything new.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- k3s `v1.37.1+` shipping (ADR-0030's own flip condition, PR #1607).
- A new release/GHSA against any pinned source.
- Oracle's Always Free capacity actually freeing up.
- A later cycle in this same run, once meaningfully more time has passed
  — currency re-checks this soon after the last one add no information;
  a later cycle should pick a genuinely different surface again.

This is cycle 29's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
