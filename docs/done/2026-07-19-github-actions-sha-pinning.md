# Pin GitHub Actions to commit SHAs instead of floating major tags

(CHARTER **Core Values** §"Everything as code" + supply-chain-security theme
adjacent to ADR-0022 (Trivy/SBOM continuous scanning); janitor fallback role,
`executor.prompt.md` STEP 6b — planner/upgrade-drafter/doc-drift-author/triager
all found real work earlier this run, but this cycle's own upgrade-drafter
pass surfaced a related, safer finding worth landing directly.)

While auditing `.github/workflows/*.yml` for outdated action versions
(`actions/checkout@v4`, `actions/cache@v4`, `actions/github-script@v7`,
`hashicorp/setup-terraform@v3`), found real major-version bumps available
upstream for all four (confirmed via each repo's `package.json` at the
candidate tag) — filed as issue #608 for architect/human review rather than
auto-built, since a major CI-tooling bump could break the CI gate itself and
this session cannot fully verify GitHub-hosted runner Node-version
compatibility ahead of time.

A safer, related, zero-behavior-change hardening was available immediately,
though: every one of these `uses:` references was pinned to a **floating major
tag** (`@v4`, `@v3`, `@v7`) rather than an immutable commit SHA — the tag's
publisher can silently re-point it to different code at any time (a real
supply-chain risk GitHub's own security hardening guidance calls out
explicitly). Pinned each to the exact commit SHA the currently-used tag
resolves to today (verified via `git ls-remote --tags`, not guessed), with a
trailing `# vX.Y.Z` comment for human readability:

- `actions/checkout@v4` → `@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.0`
- `actions/cache@v4` → `@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0`
- `actions/github-script@v7` → `@f28e40c7f34bde8b3046d885e986cb6290c5673b # v7.0.1`
- `hashicorp/setup-terraform@v3` → `@b9cd54a3c349d3f38e8881555d616ced269862dd # v3.1.2`

Applied across all 5 workflow files that reference these actions
(`auto-update-prs.yml`, `ci.yml`, `oracle-cluster-apply.yml`,
`oracle-cluster-apply-retry.yml`, `pr-up-to-date.yml`) — 15 `uses:` lines
total. Zero behavior change: same exact code runs, just addressed
immutably instead of by a mutable tag.

New `tests/github-actions-pins.bats`: asserts every `uses:` step across
`.github/workflows/*.yml` is SHA-pinned (40-char hex) with a human-readable
version comment — a recurrence guard so a future workflow edit that adds a
floating-tag `uses:` line fails `make ci`. Verified the guard actually catches
drift (tested against a scratch fixture with a floating `@v4` tag before
committing). `make ci` passes; full local bats suite (bats installed
in-sandbox): 2216/2229 pass, the 13 failures are the same pre-existing,
unrelated sandbox-environment set confirmed across every other PR this run.

## PR

(filled in after PR creation)
