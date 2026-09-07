# Correct a fabricated GHSA ID in docs/dependency-register.md's Harbor row (CVE-2026-4404 mischaracterized as Low/disputed; real advisory is Critical, already correctly audited in ADR-0024, lab unaffected)

While re-checking Harbor's currency as part of this run's oldest-reviewed-row
sweep, found a real error in `docs/dependency-register.md`'s Harbor row (dated
2026-08-20): it cited `GHSA-56j8-6qr5-cg75` for CVE-2026-4404, described as
"Low... disputed by the Harbor maintainers as not a legitimate
vulnerability."

## What was found

- **`GHSA-56j8-6qr5-cg75` does not exist** — fetched directly, HTTP 404. This
  was a fabricated/hallucinated GHSA ID from the 2026-08-20 sweep (ADR-0004).
- **The real advisory for CVE-2026-4404 is `GHSA-hj7x-hmf2-hc2p`** —
  confirmed via a direct fetch of GitHub's own advisory page: **Critical**
  (CVSS 9.4, CWE-798 Use of Hard-coded Credentials + CWE-1393 Use of Default
  Password), **not** disputed or withdrawn. Harbor ships hard-coded default
  admin credentials (`admin`/`Harbor12345`) for `<= 2.15.0`.
- **This is not a new finding** — `docs/decisions/adr-0024-harbor-not-artifactory.md`
  already has a correct, dated Re-evaluation log entry for this exact CVE
  from **2026-07-28** (audit #774): same CVE number, correct severity
  (CVSS 9.4), correct affected range (`<=2.15.0`), correct fix version
  (`2.15.1`+), and the correct "kept" reasoning (this lab's pin is past the
  floor, and independently never relies on the default password anyway). The
  2026-08-20 register sweep re-audited the same CVE three weeks later,
  arrived at a wildly different (and wrong) conclusion, and never
  cross-referenced the ADR's own already-correct prior finding.
- **This lab was never actually exposed**, confirmed independently in this
  session: `gitops/secrets/harbor-admin-externalsecret.yaml` renders
  `HARBOR_ADMIN_PASSWORD` from Vault path `secret/harbor/admin` (seeded by
  `scripts/vault-bootstrap.sh` with a random 16-byte hex value), so the
  hard-coded default credential is never in play regardless of chart
  version — matching ADR-0024's own defense-in-depth reasoning exactly.

## What was fixed

`docs/dependency-register.md`'s Harbor row corrected with the real GHSA ID,
accurate severity, and a citation back to ADR-0024's own prior audit. The
GHSA-56j8-6qr5-cg75 mentions in `docs/backlog/2026-08-19-action-needed-fresh-run-dependency-drift-sweep-clean.md`
and `docs/done/2026-08-20-dependency-register-harbor-kiali-currency-sweep.md`
are deliberately **left untouched** — both are historical point-in-time
records under this repo's own "docs/done/ is a permanent record, never
retroactively edited" convention (the same reason a completed item's ROADMAP
text gets trimmed to a pointer rather than rewritten in place). This file is
the correction record.

`docs/decisions/adr-0024-harbor-not-artifactory.md` itself needed **no**
change — its 2026-07-28 entry was already accurate; only the register's own
independent (and wrong) re-audit needed fixing.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose correction
in a markdown table cell, no code/manifest touched. Every claim was verified
against a primary source in this session: GitHub's own advisory pages for
both the fabricated ID (404) and the real one (full advisory text), plus a
direct read of `gitops/secrets/harbor-admin-externalsecret.yaml` and
`scripts/vault-bootstrap.sh` confirming this lab's actual non-exposure.

Found via a coverage/hardening sweep (executor STEP 6b fallback chain, this
run's eleventh consecutive cycle with a fully-gated "Now / next" lane) — the
oldest-reviewed-row lens already used earlier this run (Oracle Cloud
Infrastructure, Forgejo), applied once more; this time the check surfaced an
accuracy bug in a prior sweep rather than a currency gap.

## PR

(filled in once the PR is opened)
