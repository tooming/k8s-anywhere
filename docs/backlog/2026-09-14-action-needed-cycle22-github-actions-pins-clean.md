# [Action needed] Cycle 22 — GitHub Actions pin currency re-check, clean

## This run so far

Twenty-one PRs shipped this run (#1588–#1608). See prior
`docs/backlog/2026-09-14-*.md` files for each cycle's detail.

## This cycle

Live-checked every SHA-pinned GitHub Action used across `.github/workflows/*.yml`
against its real upstream release feed:

- `actions/checkout@...` (pinned `v7.0.1`) — `github.com/actions/checkout/releases`
  confirms `v7.0.1` is still the newest tag.
- `actions/cache@...` (pinned `v6.1.0`) — `github.com/actions/cache/releases.atom`
  confirms `v6.1.0` is the newest tag on the mainline (a same-day `v5.1.0`
  backport release exists on an older major line, not newer).
- `hashicorp/setup-terraform@...` (pinned `v4.0.1`) —
  `github.com/hashicorp/setup-terraform/releases` confirms `v4.0.1` is still
  newest.
- `actions/github-script@...` (pinned `v9.0.0`) —
  `github.com/actions/github-script/releases` confirms `v9.0.0` is still
  newest.

All four pins are current. No bump due.

## Assessment

Twenty-two consecutive cycles this run have worked the fallback chain from
independent angles. Four of the last five turned up real, substantive work
(#1605 docs fix, #1606 ArgoCD bump, #1607 k3s v1.37.0 evaluation, and this
cycle's clean re-check rounds out a full sweep of every externally-tracked
version pin this repo carries — Terraform/Terragrunt, ArgoCD, Traefik,
cert-manager, k3s, and now the GitHub Actions themselves).

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- A new release/GHSA against any pinned source (Actions included, now that
  this sweep has covered them).
- k3s `v1.37.1+` shipping (ADR-0030's own flip condition, PR #1607).
- Oracle's Always Free capacity actually freeing up.
- A later cycle in this same run, once meaningfully more time has passed.

This is cycle 22's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
