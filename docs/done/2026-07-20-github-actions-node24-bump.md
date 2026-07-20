# GitHub Actions major-version bumps — Node 24 (checkout v7.0.0, cache v6.1.0, github-script v9.0.0, setup-terraform v4.0.1)

CHARTER **Core Values** §"Clusterless gates stay green" + general CI hardening; RFC #611 —
architect decision 2026-07-20, resolving issue #608's open Node-runtime question.
**No prerequisites — executor may pick up immediately.** RFC #611's binding decision,
verified against real sources (ADR-0004): GitHub-hosted `ubuntu-latest` runners cache both
Node.js 22.23.1 and 24.18.0 today (`actions/runner-images`' `Ubuntu2404-Readme.md`, fetched
directly), and GitHub now requires actions to run on Node ≥24 (`github.blog` changelog,
2025-09-19 Node 20 deprecation). None of this repo's workflows use the
`pull_request_target`/`workflow_run` triggers checkout v7.0.0 restricts (confirmed by grep
across `.github/workflows/`), and the repo's one github-script step
(`auto-update-prs.yml`) uses only the injected `github`/`context` globals and
`require('child_process')`, never `require('@actions/github')` or a `getOctokit`
redeclaration — so v9.0.0's ESM migration is a non-issue.

Updated all 15 `uses:` lines across `.github/workflows/*.yml`
(`ci.yml`, `auto-update-prs.yml`, `oracle-cluster-apply.yml`,
`oracle-cluster-apply-retry.yml`, `pr-up-to-date.yml`) to the exact commit SHAs verified
directly via `git ls-remote --tags` against each upstream repo (not inferred):

- `actions/checkout` → `9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` # v7.0.0
- `actions/cache` → `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` # v6.1.0
- `actions/github-script` → `3a2844b7e9c422d3c10d287c895573f7108da1b3` # v9.0.0
  (the annotated tag's *peeled* commit — `git ls-remote --tags` lists the tag-object SHA
  `d746ffe35508b1917358783b479e04febd2b8f71` first; that SHA is NOT a valid pin target for
  a GitHub Actions `uses:` line, which resolves against a commit, not a tag object)
- `hashicorp/setup-terraform` → `dfe3c3f87815947d99a8997f908cb6525fc44e9e` # v4.0.1

Extended `tests/github-actions-pins.bats` (existing generic SHA-pin/version-comment
structural checks from `chore/github-actions-sha-pinning`, PR #609) with five new
assertions: one per bumped action pinning the exact new SHA/version, plus a recurrence
guard asserting none of the four pre-bump SHAs remain anywhere in `.github/workflows/`.

`make ci` passes. Per RFC #611, this PR's own GitHub Actions run (lint, unit, drift,
manifests, terraform, kustomize, up-to-date — all executing on the four bumped actions) IS
the live verification here, unlike most bumps in this repo where a clusterless caveat is
needed: every one of those jobs ran green on the bumped action versions themselves.

Closes #611.

## PR

https://github.com/tooming/k8s-anywhere/pull/614
