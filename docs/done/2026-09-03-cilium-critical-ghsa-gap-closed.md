# Cilium: Critical advisory GHSA-3fcv-jvfp-m4q9 found unaudited, confirmed not applicable

Enumerated `github.com/cilium/cilium`'s published security advisories directly
(not just the "new since the last date-filtered search" query ADR-0014's
2026-08-19 entry used) and found **GHSA-3fcv-jvfp-m4q9** ("Sensitive information
disclosure and cluster disruption via local Envoy admin socket access",
**Critical**, CVE-2026-49445, published 2026-06-01) — a Critical-severity advisory
that predates the 2026-08-19 entry but was never recorded in ADR-0014's
Re-evaluation log. The 2026-08-19 entry's own trigger was scoped to "three new
High-severity GHSAs published 2026-08-12" — a narrower, date-filtered search that
structurally couldn't have surfaced an already-published June advisory it wasn't
looking for. Not a claim the 2026-08-19 audit was wrong for its own stated scope,
but a real gap this closes: a Critical advisory sat unrecorded for three months.

## Verification

Confirmed directly (not assumed, ADR-0004): the advisory's own affected/patched
ranges are `<1.19.2`, `1.18.0`–`1.18.7` (patched `1.18.8`), `<1.17.14` (patched
`1.17.14`). This lab's pin (`1.18.13`) is past the `1.18.x` fix floor (`1.18.8`)
by five patches — not affected. The vulnerability itself (an
insufficiently-protected local Envoy admin socket, exploitable by a local user on
the same node) requires Cilium's L7 functionality to be enabled; independent of
that, the pin is simply past the fix regardless.

## Scope note

This was a targeted check of one Critical advisory found via a broader listing
pass, not an exhaustive re-audit of every advisory across Cilium's full
multi-page advisory history (a spot-check of page 2's ten Moderate/Low advisories
found nothing above Moderate severity and nothing suggesting a floor above
`1.18.13`, but pages 3+ were not exhaustively walked this cycle) — said plainly
per ADR-0004 rather than overclaiming completeness. A future cycle wanting
stronger assurance should walk Cilium's full multi-page advisory list end-to-end.

## What changed

- `docs/decisions/adr-0014-cilium-not-flannel-policy.md`: new Re-evaluation log
  entry.
- `docs/dependency-register.md`: Cilium row updated.

No code change — the pin (`1.18.13`) is unaffected and needs no bump.

`make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1392
