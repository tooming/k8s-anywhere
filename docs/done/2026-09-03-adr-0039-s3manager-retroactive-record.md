# Author ADR-0039 — s3manager as the lab's Garage (S3) browser UI (retroactive record); bump `v0.8.0` → `v0.9.0`

s3manager (`gitops/storage/s3manager/`) has been a real, live, always-on
component with its own genuine version-bump history since 2026-07-28 — yet,
like moto/ACK-S3/KRO before ADR-0038, it had no governing ADR and no
`docs/dependency-register.md` row. Its real version history instead lived
only as inline YAML comments in `gitops/storage/s3manager/deployment.yaml`,
the same shape ADR-0038 found and fixed for ACK-S3.

## What changed

- **New `docs/decisions/adr-0039-s3manager-garage-browser-ui.md`**: retroactive
  governance record — role, image pin (by digest, not tag), NetworkPolicy,
  test coverage, and a Re-evaluation log migrating both prior inline
  version-bump entries plus a new currency+GHSA sweep.
- **`gitops/storage/s3manager/deployment.yaml`**: image digest bumped
  `v0.8.0` → `v0.9.0` (confirmed real via Docker Hub's tags API and a real
  commit-history diff — dependency updates, a new "open action" feature, a
  Materialize→BeerCSS front-end framework migration, code simplification; no
  CVE either direction, zero published GHSA advisories exist for this repo).
  Removed the inline version-history comment (migrated to the ADR).
- **`docs/decisions/README.md`**: added the ADR-0039 index entry.
- **`docs/dependency-register.md`**: added one new row (s3manager); fixed the
  Scope note's arithmetic (38→39 ADRs, 37→38 rows).

## ADR-0004 caveat, explicitly noted

This remote clusterless session cannot visually verify the CSS-framework
migration renders correctly in a browser. s3manager is stateless (no
persistence, every view is a live read against Garage) and pinned by digest,
so the rollback path is a one-line digest revert with zero data-loss risk if
the new UI renders badly.

## Why this is real (not manufactured) ARCHITECT-fallback work

Found via this run's coverage/hardening sweep (ROADMAP rule #9's fallback
chain) after the "Now / next" lane was re-confirmed fully gated and
PLANNER/ARCHITECT/TRIAGER all came up empty. Same shape as the ADR-0036/
ADR-0037/ADR-0038 gaps closed earlier this run. No binding ADR is
contradicted or superseded.

`make ci` passes green.

## PR

(filled in after PR creation)
