# Closed a real governance gap: External Secrets Operator had no ADR (cycle 12)

**Date:** 2026-08-19
**Cycle:** 12th cycle this run

## What was found

Continuing this run's direct-GHSA-advisory-page security sweep (cycle 6-11's
method) to External Secrets Operator (ESO) and Longhorn turned up a genuine
structural gap, not just another version-currency confirmation: **ESO — an
always-on-core, security-critical component that mediates every credential
in the cluster (Garage, Harbor, Grafana, Kargo, Velero, ACK, capstone) via a
Vault-backed `ClusterSecretStore` — had no dedicated ADR and, consequently,
no `docs/dependency-register.md` row.** Every peer component (RabbitMQ,
Valkey, Kyverno, cert-manager, KEDA, Argo Rollouts, Velero, Trivy Operator)
has one; ESO's PSA `restricted` classification was recorded inside ADR-0017
(RFC #229) but the component itself never got its own record, so the
register — which explicitly scopes itself to "pure re-indexing of ADR
content" — had nothing to index.

## What was shipped

- **`docs/decisions/adr-0036-external-secrets-vault-sync.md`** — new,
  retroactive ADR documenting the already-implemented decision: chart pin
  (`2.9.0`, verified newest via `git ls-remote --tags`), security posture
  (PSA restricted, NetworkPolicy fan-out, trimmed resource limits — all
  already live, verified directly against the manifests), observability,
  test coverage, and this cycle's own GHSA sweep (see below).
- **`docs/decisions/README.md`** — new ADR-0036 index entry.
- **`docs/dependency-register.md`** — new External Secrets Operator row
  (citing ADR-0036); Longhorn's row also refreshed with this cycle's
  independent GHSA re-check.
- **`docs/decisions/adr-0013-longhorn-block-storage.md`** — new
  Re-evaluation log entry: Longhorn's only two advisories (both High) date
  to 2021, long predating the current `1.11.3` pin — confirms the existing
  currency-based Keep decision from a different angle (security advisories,
  not release-tag currency).

## Security findings (both components confirmed already safe)

- **External Secrets Operator** (`2.9.0` pin) — 7 advisories total,
  including one **Critical** (GHSA-77v3-r3jw-j2v2, insecure `getSecretKey`
  templating, affects `>=0.20.2,<1.2.0`, patched `1.2.0`) and three High.
  The current pin sits past every fix floor found and is also the newest
  upstream tag — no currency gap either.
- **Longhorn** (`1.11.3` pin) — only 2 advisories total, both from
  2021-12-17, both irrelevant to the current pin by four-plus major lines.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, still open, no
new confirmation).

## Why this is the honest deliverable

Not another "confirmed safe, nothing to change" cycle — a real, previously
undocumented governance gap on a security-critical component, closed with a
verified (not fabricated, ADR-0004) retroactive ADR. Not a stopping point —
the run continues from STEP 1 per STEP 8.
