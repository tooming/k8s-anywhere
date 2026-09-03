# cert-manager full GHSA sweep — `1.21.1` pin confirmed clean

Extending this run's "check every published advisory directly" technique (Envoy
Gateway, Cilium, ArgoCD) to cert-manager. `github.com/cert-manager/cert-manager/
security/advisories` lists exactly three published advisories — a small enough
total to sweep exhaustively.

## Verification

Confirmed directly (not assumed, ADR-0004):

| Advisory | CVE | Severity | Affected | Patched |
|---|---|---|---|---|
| GHSA-8rvj-mm4h-c258 | (already tracked) | High | `1.18.0`-`1.20.2` | `1.19.6`, `1.20.3` |
| GHSA-gx3x-vq4p-mhhv | (already tracked) | Moderate | `1.18.0`-`1.18.4`, `1.19.0`-`1.19.2` | `1.18.5`, `1.19.3` |
| GHSA-r4pg-vg54-wxx4 | none assigned | Low | `<1.12.14`, `<1.15.4`, `<1.16.2` | `1.16.2`, `1.15.4`, `1.12.14` |

The first two were already accounted for in the 2026-08-19 register entry. The
third (PEM-parsing DoS via `pem.Decode()`, published 2024-11-20) had not been
explicitly checked before. The current pin (`1.21.1`) is past all three floors.

## Decision: keep `1.21.1`

No security-driven reason to bump. All three published advisories are now
accounted for.

## What changed

- `docs/decisions/adr-0028-cert-manager-tls-lifecycle.md`: new Re-evaluation log
  entry.
- `docs/dependency-register.md`: cert-manager row updated.

No code change. `make ci` passes green.

## PR

(filled in after PR creation)
