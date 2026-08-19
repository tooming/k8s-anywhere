# [Action needed] Now/next still gated; cert-manager and KEDA confirmed safe (cycle 11)

**Date:** 2026-08-19
**Cycle:** 11th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep against two more
always-on-core components not yet checked this way (`docs/decisions/`
tracks both under binding ADRs):

- **cert-manager** (`1.21.1` pin, `gitops/platform/cert-manager.yaml`) — 3
  advisories total. The one High (GHSA-8rvj-mm4h-c258, ACME Challenge
  DNS01-solver-policy bypass) affects `1.18.0`-`1.20.2`, patched at
  `1.19.6`/`1.20.3`. The one Moderate (GHSA-gx3x-vq4p-mhhv, DNS-response DoS)
  affects `1.18.0`-`1.18.4` and `1.19.0`-`1.19.2`, patched at
  `1.18.5`/`1.19.3`. Current pin `1.21.1` sits past both fix floors.
  `git ls-remote --tags` confirms `v1.21.1` is also the newest tag — no
  currency gap either.
- **KEDA** (`2.20.2` pin, `gitops/platform/keda.yaml`) — 3 advisories total.
  The one High (GHSA-c4p6-qg4m-9jmr, Vault arbitrary file read) affects the
  operator at `≤2.17.2`/`≤2.18.2`, patched at `2.17.3`/`2.18.3`/`≥2.19.0`.
  The one Moderate (GHSA-6w3m-4hhp-775q, Postgres connection-string
  injection) affects `≤2.19.x`, patched at `2.20`. Current pin `2.20.2`
  sits past both fix floors and `git ls-remote --tags` confirms it's the
  newest tag too.

`docs/dependency-register.md`'s cert-manager and KEDA rows updated with the
verified findings (2026-08-19 entries, superseding the prior currency-only
notes).

## What's blocked

Unchanged: the "Now / next" lane holds the same three items — two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes (auth-model change, no live cluster to verify against), and the
capstone `Deployment` removal gated on issue #633 (re-checked directly via
the GitHub API this cycle — still open, `updated_at` unchanged at
2026-08-17T18:50:01Z, no new confirmation comment).

## Why this is the honest deliverable

Two more security-critical, ADR-governed components independently checked
against their authoritative advisory pages and confirmed already safe and
current — not a new gap, but a real, previously-undocumented-at-this-detail
confirmation (the register's prior entries only noted routine version
bumps, not the underlying CVE floors). No code shipped this cycle. Not a
stopping point — the run continues from STEP 1 per STEP 8.
