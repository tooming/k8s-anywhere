# Author ADR-0037 — HashiCorp Vault for secrets management (retroactive record)

HashiCorp Vault — CHARTER's own Goals section names the "secrets flow (Vault →
External Secrets → workload)" explicitly — had no dedicated ADR and no
`docs/dependency-register.md` row, unlike every other always-on-core component.
Worse than External Secrets Operator's own gap (ADR-0036, 2026-08-19): Vault's
actual version-history/security-audit trail lived inline as YAML comments in
`gitops/platform/vault.yaml` — the only version-sensitive component in this repo
that carried its audit trail there instead of an ADR's own Re-evaluation log.
Found via this cycle's continuation of the run's gap-analysis/security-sweep
pattern applied to this lab's remaining un-ADR'd always-on-core components.

## What changed

- **New `docs/decisions/adr-0037-vault-secrets-management.md`**: a retroactive
  governance record (mirrors ADR-0036's own precedent and structure) covering
  Context, Decision (chart/image pin, storage, TLS/injector posture), Security
  posture, Observability, Test coverage, Scope & exceptions, and a
  **Re-evaluation log** migrating all four pre-existing entries from
  `vault.yaml`'s inline comments verbatim (2026-07-24 pin, 2026-08-05 bump,
  2026-08-19 chart bump) plus a new fifth entry for this cycle's work.
- **Server image bumped `2.0.4` → `2.1.0`** (found while authoring the ADR and
  re-checking currency): `v2.1.0` (2026-09-01) fixes two real Go-vulnerability-
  database dependency issues (`GO-2026-6107` etcd client, `GO-2026-5052`
  go-pkcs12 — a different, coincidentally-similarly-numbered identifier from the
  already-fixed `CVE-2026-5052`). No GitHub-native advisories exist for
  `hashicorp/vault` at all (HashiCorp publishes bulletins separately via
  `discuss.hashicorp.com`, still egress-blocked from this sandbox — same
  limitation every prior entry in the migrated history already hit).
  `gitops/vault/unsealer.yaml`'s image bumped in lockstep (its CLI talks to the
  server's API, so the two must agree).
- `gitops/platform/vault.yaml`: the large inline Re-evaluation log comment block
  replaced with a short pointer to ADR-0037 — matching every other
  version-sensitive component in this repo.
- `tests/securitycontext-vault.bats`: pin assertions updated to `2.1.0` on both
  the server and unsealer images, with new "no stray `2.0.4`" guards on each.
- `docs/decisions/README.md`: new ADR-0037 index entry.
- `docs/dependency-register.md`: new Vault row; Scope note arithmetic updated
  (37 ADRs indexed, 34 distinct third-party-tool rows) — verified via
  `make dependency-register-check`, not hand-counted.

## Verification (ADR-0004)

Caught and corrected my own mistake mid-research: an initial fetch of
`hashicorp/vault`'s `main`-branch `CHANGELOG.md` for the "v2.1.0" tag resolved to
an unrelated Enterprise-line section (a WebFetch ambiguity, not a real absence of
the release) — cross-checked against the real GitHub releases list and the
specific `releases/tag/v2.1.0` page instead, which confirmed the release, its
2026-09-01 date, and its actual Security-heading content directly.

`make ci` passes green (lint/readme-check/lab-ui-check/all drift detectors
including `dependency-register-check.sh`'s Scope-note arithmetic check —
bats/kustomize/terraform tools aren't installed in this clusterless session; the
full suite runs in GitHub Actions).

## PR

(filled in after PR creation)
