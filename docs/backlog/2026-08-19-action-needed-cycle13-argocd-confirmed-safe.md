# [Action needed] Now/next still gated; ArgoCD itself confirmed safe (cycle 13)

**Date:** 2026-08-19
**Cycle:** 13th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep to the platform's own
control plane: **ArgoCD** (Terraform-bootstrapped, `infra/modules/argocd`,
chart `10.4.0` / appVersion `v3.5.1`).

`github.com/argoproj/argo-cd/security/advisories` lists 8 advisories total,
including 2 **Critical** and 3 High. Checked each severity-High-or-above
entry's own affected/patched-version fields directly:

- GHSA-3v3m-wc6v-x4x3 (**Critical**, Kubernetes Secret extraction via
  ServerSideDiff) — affects `3.2.0`-`3.3.8`, patched `3.3.9`/`3.2.11`.
- GHSA-786q-9hcg-v9ff (**Critical**, CVE-2025-55190, project API token
  exposes repo credentials) — affects `>=2.2.0-rc1`, patched
  `3.1.2`/`3.0.14`/`2.14.16`/`2.13.9`.
- GHSA-h98r-wv3h-fr38 (High, stored XSS → privilege escalation) — affects
  `<3.0.0`, patched `3.2.12`/`3.3.10`/`3.4.2`.
- GHSA-rg3g-4rw9-gqrp (Moderate, same secret-extraction class as the
  Critical above) — affects `3.2.0`-`3.2.11`/`3.3.9`/`3.4.1`, patched
  `3.2.12`/`3.3.10`/`3.4.2`.

**Current pin (`v3.5.1`, chart `10.4.0`) sits past every floor found.**
`git ls-remote --tags` against `argoproj/argo-helm` confirms `argo-cd-10.4.0`
is also the newest chart tag — no currency gap either.
`docs/dependency-register.md`'s ArgoCD row updated with this cycle's
verified finding.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, still open, no
new confirmation).

## Why this is the honest deliverable

The platform's own control plane — arguably the single highest-value
target for this kind of check — independently confirmed safe and current.
No code shipped this cycle. Not a stopping point — the run continues from
STEP 1 per STEP 8.
