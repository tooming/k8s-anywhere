# Envoy Gateway full GHSA sweep — `v1.8.3` pin confirmed security-clean

ADR-0008's deliberately-held Envoy Gateway pin (`v1.8.3`, held back from `v1.9.0`
since 2026-08-18 over a Gateway API CRD breaking change this clusterless session
can't verify renders cleanly) had only ever been re-checked for "does a newer
release exist," never systematically checked against every published security
advisory to confirm the *current* pin itself isn't secretly vulnerable to
something already fixed further upstream.

Verified directly (not assumed, ADR-0004): fetched all 10 published advisories
from `github.com/envoyproxy/gateway/security/advisories` and their individual
affected/patched version ranges:

| Advisory | CVE | Severity | Affected | Patched |
|---|---|---|---|---|
| GHSA-wcrf-9vrr-854f | CVE-2026-53713 | Critical | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-22xc-xg2r-9j7v | CVE-2026-53714 | High | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-xrwg-mqj6-6m22 | CVE-2026-22771 | High | `<1.5.7`, `<1.6.2` | `1.5.7`, `1.6.2` |
| GHSA-j777-63hf-hx76 | CVE-2025-24030 | High | `<1.2.6` | `1.2.6` |
| GHSA-fcrp-7gc2-93g7 | CVE-2026-53718 | Moderate | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-8fv2-88gg-hm7q | CVE-2026-53715 | Moderate | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-m2v6-2jmh-4c68 | CVE-2026-53719 | Moderate | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-h7pq-86h8-rp5x | CVE-2026-53717 | Moderate | `<1.7.3`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-cxpq-8v7q-cg56 | CVE-2026-53716 | Moderate | `<1.7.4`, `<1.8.1` | `1.7.4`, `1.8.1` |
| GHSA-mf24-chxh-hmvj | CVE-2025-25294 | Moderate | `<1.2.7`, `<1.3.1` | `1.2.7`, `1.3.1` |

Every affected range tops out at `1.8.1` or lower — the current pin (`v1.8.3`) is
past every published floor, including the lone Critical (GHSA-wcrf-9vrr-854f, a
Lua-script `EnvoyExtensionPolicy` path-validation bypass; this lab doesn't define
any such policy, so it wouldn't be exploitable here even pre-fix, but the pin is
past the fix regardless).

## Decision: keep `v1.8.3`

No security-driven reason exists to bump. The breaking-change hold from the
2026-08-18 entry (a Gateway API CRD version bump needs live verification this
clusterless session can't provide) is the only remaining reason this pin isn't on
`v1.9.0`, unchanged by this cycle's finding.

## What changed

- `docs/decisions/adr-0008-envoy-gateway-not-traefik.md`: new Re-evaluation log
  entry with the full advisory table.
- `docs/dependency-register.md`: Envoy Gateway row updated.

`make ci` passes green.

## PR

(filled in after PR creation)
