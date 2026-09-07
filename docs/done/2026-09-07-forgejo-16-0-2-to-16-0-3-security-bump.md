# Bump Forgejo `16.0.2` → `16.0.3` (3 named security fixes) + forgejo-runner `13.0.0` → `13.1.0` (routine currency)

`docs/dependency-register.md`'s Forgejo row was last reviewed 2026-08-17 (the
live cutover) — 21 days old, one of the oldest active rows — with a narrower
2026-09-06 note only about a registry switch (`codeberg.org` →
`code.forgejo.org`), not a version-currency check. Checked directly against
real upstream sources (`codeberg.org`/`forgejo.org` are both egress-blocked
from this sandbox — used a GitHub mirror, `raw.githubusercontent.com/
doc-sheet/forgejo/forgejo/release-notes-published/16.0.3.md`, for the
release notes' actual content):

## Forgejo `16.0.2` → `16.0.3`

Real, named security fixes per the upstream release notes:

- Public-only and repo-specific access control on
  `/repos/{owner}/{repo}/pulls/{index}/update`.
- Reusable-workflow expansion from a base branch with `pull_request_target`
  (a privilege-escalation-shaped class of bug).
- Disallowing `owner` as a collaboration access mode.
- Dependency security patches: `golang.org/x/image`, `golang.org/x/mod`,
  plus Mermaid and PostCSS.

## forgejo-runner `13.0.0` → `13.1.0`

Routine currency — a minor release (2026-08-31): a new experimental plugin
capability, terminal-command handling changes, and dependency upgrades. No
named CVE fix, but no ADR pin blocks taking it and it's the newest stable
`13.x` release.

## What was changed

- `forgejo/docker-compose.yml`: both image pins bumped, with the exact
  citation trail recorded inline (matching this file's own established
  comment style for prior bumps).
- `tests/forgejo-compose.bats`: updated the exact-pin assertions for both
  services, added matching "does not pin the stale version" negative tests
  (mirroring `tests/ci-tool-pins.bats`'s own established pattern). Also
  bumped a `grep -A7` → `-A13` fixed-line-count assertion
  ("forgejo-runner depends on forgejo being healthy") that the runner's
  version-bump comment block pushed out of its old window — the exact same
  fragility class this file's own healthcheck test comment already
  documents having hit before (bumped 60→70→80 there).
- `docs/dependency-register.md`: Forgejo row updated with today's date and
  both findings.

## Verification caveat (ADR-0004)

Neither new image tag's actual pull was verified from this sandbox — both
`codeberg.org` and `forgejo.org` (and `code.forgejo.org`) are egress-blocked
here, the same registry-reachability constraint the 2026-09-06 finding
already documents for the *previous* tag. The release notes' content itself
was independently confirmed via a GitHub mirror (a primary-source document,
not a search-engine summary), but whether `code.forgejo.org/forgejo/
forgejo:16.0.3` / `.../runner:13.1.0` actually resolve and pull cleanly is
this bump's real, not-yet-exercised verification — the next live `make up`/
`make forgejo-up` is where that happens, same standing caveat as every other
currency bump in this file.

`make ci` fully green (exit 0, zero `not ok` lines) — this compose file
lives outside `gitops/`, so no kubeconform/kustomize validation applies to
it; the bats structural assertions above are the only mechanical coverage.

Found via a coverage/hardening sweep (executor STEP 6b fallback chain, this
run's tenth consecutive cycle with a fully-gated "Now / next" lane) — the
oldest-reviewed-row lens that already found the Oracle Cloud Infrastructure
gap earlier this run, applied to the next-oldest active row.

## PR

https://github.com/tooming/k8s-anywhere/pull/1483 (auto/forgejo-16-0-2-to-16-0-3-security-bump)
