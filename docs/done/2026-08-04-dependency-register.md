# Third-party dependency register — `docs/dependency-register.md`

(CHARTER **Goals** §"operational-resilience discipline" — DORA Pillar 4 (ICT
third-party risk management); planner-fallback gap analysis 2026-08-04, reached via
`executor.prompt.md` STEP 6b after all three standing "Now / next" items were found
gated on unconfirmed maintainer-confirmation issues #631/#633 with no live-state-safe
slice to split off. **No prerequisites — executor may pick up immediately.**)
Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s Q14
("Is there a register of ICT third-party dependencies?") answered "Not as a single
consolidated register — but the information exists, scattered across the ADRs in
`docs/decisions/`" and its own "Gap" line named the exact cheap fix: a
`docs/dependency-register.md` tabulating (tool, criticality, upstream source, ADR,
last-reviewed date) purely re-indexing existing ADR content, "without gathering new
information."

Added `docs/dependency-register.md`: one row per real third-party tool named in a
binding ADR, columns Tool | Criticality | Upstream source | ADR | Last reviewed.
Read all 27 non-superseded ADRs (ADR-0001–0029 minus the two Superseded, ADR-0010/
ADR-0011) directly to extract this data (used a research agent for the initial bulk
extraction pass, then spot-verified several of its findings — ADR-0001, ADR-0002,
ADR-0007, ADR-0012, ADR-0027 — directly against the source files before trusting
them, per this repo's "verify before asserting" discipline).

**Scope decision made during implementation:** 7 of the 27 ADRs decide a policy or
architectural posture rather than a single third-party product (ADR-0003, ADR-0004,
ADR-0005, ADR-0016, ADR-0017, ADR-0025, ADR-0026) — excluded from the table with an
explicit "Scope note" section explaining why, rather than force-fitting them into
columns designed for third-party risk fields they don't have. The remaining 20 ADRs
name 22 distinct tools (ADR-0001 and ADR-0012 each decide two tools at once; Garage
is named by two ADRs — 0002 and 0007, for two different roles — and gets one merged
row rather than being double-counted). ADR-0027's Oracle Cloud/k3s pairing didn't fit
the three-tier criticality scheme from the ROADMAP item's own spec (always-on-core /
always-on-next-wave / heavy-on-demand), since it's an opt-in alternate infra backend,
not a component running alongside the localhost stack — added a fourth
"cloud-backend (opt-in)" tier for those two rows rather than mis-classifying them.

**Honesty finding, not fabricated (ADR-0004):** most ADRs (22 of 27 read) state no
explicit decision date anywhere in their body — many just say "Status. Adopted" with
no date, or "Decision taken in RFC #NN" without a date either. Rather than guess or
substitute a Re-evaluation-log date as a stand-in for a genuinely-undocumented
decision date, rows without a Re-evaluation log AND without a stated decision date
are marked "not dated in ADR" — an honest gap in the source ADRs themselves, not
something this register invents its way around.

Updated `docs/dora-audit-readiness.md`'s Q14 answer from "Not as a single
consolidated register" to "Yes" (cites the new file, 22 tools / 20 ADRs), updating
its "Gap" line to note the register has no mechanical drift guard yet (a manual
snapshot, said explicitly rather than implying a freshness guarantee that doesn't
exist) and that the "not dated in ADR" rows are a pre-existing ADR gap, not a
register shortcoming. New `tests/dependency-register.bats`: file exists, five-column
header present, ≥20 data rows, spot-checks two specific stable rows (Garage/ADR-0002,
Valkey/ADR-0018), confirms the doc explains its relationship to the two companion
docs and its own scope exclusions, ADR-0004 fabrication guard, and that Q14's block
in the audit doc no longer contains the old negative answer and now references the
new file — every assertion hand-verified against the real files before committing.

`make ci` passed locally (lint/readme-check/lab-ui-check/roadmap-check/
markdown-links-check/drift checks green on this docs-only diff; the usual
cluster-tool checks skip in this clusterless sandbox and the bats suite runs for
real in GitHub Actions). Zero live-cluster blast radius — no `gitops/` files touched.

## PR

(filled in after PR creation)
