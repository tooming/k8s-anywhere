# Traefik basicAuth Middleware for the Argo Rollouts dashboard

Implements [RFC #1479](https://github.com/tooming/k8s-anywhere/issues/1479) —
the architect decision (2026-09-07, closing [audit #1478](https://github.com/tooming/k8s-anywhere/issues/1478))
that converted a Critical, unpatched, unauthenticated-mutation CVE
(**GHSA-366v-5xmx-36vh / CVE-2026-82277**, CVSS 9.3, CWE-306) against the
Argo Rollouts dashboard into concrete buildable work. The dashboard "binds to
all interfaces and exposes mutating Rollout operations without
authentication, authorization, or CSRF protection" (`PromoteRollout`,
`AbortRollout`, `RestartRollout`, `SetRolloutImage`, `UndoRollout`,
`RetryRollout`) — filed against exactly this lab's pinned appVersion
`v1.10.0`, with no patched version identified in the advisory. This lab's
`gitops/argo-rollouts/ingressroute.yaml` exposes exactly this dashboard at
`rollouts.127.0.0.1.nip.io` over both HTTP and HTTPS.

## What was built

A compensating control at the ingress layer, reusing the exact bcrypt/Vault
credential pattern already established for Kargo's admin login — no new
technology or secrets-management pattern introduced:

- **`gitops/argo-rollouts/dashboard-auth-externalsecret.yaml`** — a new
  `ExternalSecret` syncing Vault path `secret/argo-rollouts/dashboard` into a
  `argo-rollouts-dashboard-auth` Secret, using ESO's template feature (same
  mechanism `gitops/secrets/velero-s3-externalsecret.yaml` already uses) to
  render a `users` key as `{{ .username }}:{{ .passwordHash }}` — the exact
  `user:bcrypt-hash` shape Traefik's `basicAuth` Middleware expects.
- **`scripts/vault-bootstrap.sh`** — seeds `secret/argo-rollouts/dashboard`
  (idempotent, matching the script's existing `v kv get ... || { ... }` guard
  pattern), generating a bcrypt hash via `htpasswd -nbBC 14 admin "$PASS"`
  (cost factor 14, matching Kargo's existing precedent) and storing the
  plaintext once at generation time for first-login retrieval.
- **`gitops/argo-rollouts/dashboard-auth-middleware.yaml`** — a new
  `traefik.io/v1alpha1` `Middleware`, type `basicAuth`, referencing the Secret
  above.
- **`gitops/argo-rollouts/ingressroute.yaml`** — both route entries (the
  `web` and `websecure` IngressRoute objects) now reference the new
  Middleware, closing the gap on both entryPoints.
- **`README.md`** + **`docs/dependency-tree.md`** — both updated with a note
  that the dashboard now requires HTTP Basic Auth and the credential-retrieval
  command (`vault kv get secret/argo-rollouts/dashboard`).
- **`tests/argo-rollouts.bats`** — 8 new structural tests: the Middleware
  exists and is `basicAuth`-typed; both IngressRoute route entries reference
  it; the ExternalSecret exists, targets the right Vault path, and renders the
  `user:hash` template; `vault-bootstrap.sh` seeds the secret via the bcrypt
  pattern.

## Out of scope (per the RFC)

No other lab dashboard was touched — none carries a known, unpatched,
critical unauthenticated-mutation CVE today. The Argo Rollouts
controller/CRDs and canary mechanics (ADR-0020) are entirely unaffected; this
change is scoped to the dashboard's ingress exposure only. `gitops/platform/
argo-rollouts.yaml`'s chart pin is unchanged — no patched version exists
upstream to bump to.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines), including the 8 new bats
assertions. This is a clusterless, structural-only change — the live
credential-rotation/first-login flow (retrieving the generated password from
Vault after a real `make up`) is a manual step any operator follows the same
way as Harbor's or Kargo's existing admin credentials, not something this
sandbox can exercise end-to-end.

## PR

(filled in once the PR is opened)
