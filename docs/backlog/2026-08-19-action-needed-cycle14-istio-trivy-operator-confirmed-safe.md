# [Action needed] Now/next still gated; Istio and Trivy Operator confirmed safe (cycle 14)

**Date:** 2026-08-19
**Cycle:** 14th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep against two more
ADR-governed components:

- **Istio** (ambient mode, `1.30.3` pin) — 10 advisories total. Three are
  2026-dated High/Moderate: GHSA-v75c-crr9-733c (High, JWKS resolver
  exposes hardcoded default keys) and GHSA-974c-2wxh-g4ww (Moderate,
  cross-namespace debug-endpoint access) both patched at
  `1.29.1`/`1.28.5`/`1.27.8`; GHSA-fgw5-hp8f-xfhc (Moderate, SSRF via
  `RequestAuthentication` `jwksUri`) patched at `1.29.2`/`1.28.6` (the
  first three releases were only a partial mitigation). Current pin
  `1.30.3` sits past every floor found and `git ls-remote --tags` confirms
  it's also the newest `1.30.x` tag — no currency gap.
- **Trivy Operator** (`0.35.0` chart) — checked
  `github.com/aquasecurity/trivy-operator/security/advisories` directly:
  **zero published advisories exist for this repository at all.** Nothing
  to compare against the current pin.

`docs/dependency-register.md`'s Istio and Trivy Operator rows updated with
these verified findings.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, still open, no
new confirmation).

## Why this is the honest deliverable

Two more ADR-governed components — one a heavy-on-demand service mesh with
a real, checked CVE history all already past the current pin's floor, the
other confirmed to have no CVE history to check at all — independently
verified safe. No code shipped this cycle. Not a stopping point — the run
continues from STEP 1 per STEP 8.
