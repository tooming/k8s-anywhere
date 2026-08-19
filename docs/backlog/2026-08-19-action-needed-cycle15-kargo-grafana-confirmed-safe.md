# [Action needed] Now/next still gated; Kargo and Grafana confirmed safe (cycle 15)

**Date:** 2026-08-19
**Cycle:** 15th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep against two more
ADR-governed components:

- **Kargo** (`1.11.2` chart) — 8 advisories total, including 1 **Critical**
  (GHSA-7g9x-cp9g-92mr, authorization bypass via batch resource creation,
  affects `>=1.7.0,<=1.9.2`, patched `1.9.3`+backports) and 5 Moderate.
  Checked each: GHSA-xx8h-gw9m-m95p and GHSA-f72x-6fm6-94rq both affect
  `<1.11.0` (patched via `1.9.10`/`1.10.9` backports — `1.11.0` and later
  were never affected); GHSA-wp4p-hr79-q4g8 patched at `1.10.8` "as well as
  the upcoming 1.11 release"; GHSA-j94x-8wcp-x7hm (SSRF) patched at
  `1.9.5`. Current pin `1.11.2` sits past every floor found and
  `git ls-remote --tags` confirms it's also the newest tag — no currency
  gap.
- **Grafana** (`13.0.6` image) — checked
  `github.com/grafana/grafana/security/advisories` directly: 10 advisories
  total, all dated 2022-2023 (newest: March 2023), none apply to the
  current, much-newer `13.0.6` pin.

`docs/dependency-register.md`'s Kargo and Grafana rows updated with these
verified findings.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, still open, no
new confirmation).

## Also this cycle

Cycle 14's PR (#1259) hit a real, reproducible CI infra flake — the `lint`
job's `apt-get install shellcheck yamllint` step hung and consumed its
full `timeout-minutes` budget twice in a row. Root-caused and fixed
separately (PR #1260, merged): both the `lint` and `unit` jobs' apt-get
installs are now a bounded-retry loop (3 attempts, 90s each,
`DEBIAN_FRONTEND=noninteractive`) instead of one unbounded call. PR #1259
was then rebased onto the fix and merged clean.

## Why this is the honest deliverable

Two more ADR-governed components independently verified safe, plus a real
CI robustness bugfix (with its own mechanical-guard rationale) landed
along the way. No application code shipped this cycle. Not a stopping
point — the run continues from STEP 1 per STEP 8.
