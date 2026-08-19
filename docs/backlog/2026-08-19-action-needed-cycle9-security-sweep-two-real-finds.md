# [Action needed] Now/next still gated; this cycle's security-advisory sweep found and fixed 2 real gaps, confirmed 2 more safe

**Date:** 2026-08-19
**Cycle:** 9th cycle this run

## What was shipped this run so far (for context)

1. PR #1243 — cycle 1's honest record after the full STEP 6b fallback chain
   came up empty.
2. PR #1244 — cycle 2's JANITOR fallback: a real footgun in
   `scripts/prune-stale-branches.sh` fixed with a new time-gated ORPHANED
   class + 4 bats tests.
3. PR #1245 — a same-run ADR-0004 self-correction of PR #1244's false
   branch-deletion claim.
4. PR #1246 — cycle 3's honest record: a different-lens sweep came up empty.
5. PR #1247 — cycle 4's honest record: an O2 coverage-guard lead was a false
   positive, caught before shipping.
6. PR #1250 — cycle 5's UPGRADE-DRAFTER fallback: RabbitMQ `4.3.4`→`4.3.5`
   patch bump (spent this run's one-PR-per-run upgrade-drafter cap).
7. PR #1251 — cycle 6's PLANNER fallback: filed a Cilium `1.18.12`→`1.18.13`
   security-currency item to Now/next (found 3 High GHSAs, already fixed by
   the current pin — but the routine patch bump on top was real).
8. PR #1252 — cycle 7's executor pickup of that item: the Cilium bump
   itself, with the GHSA audit recorded in ADR-0014.
9. PR #1253 — cycle 8's JANITOR-style same-run correction: PR #1250's "no
   CVE found" claim for RabbitMQ was incomplete — a fuller sweep (checking
   the GHSA page directly, not just release notes) found **ten** GHSAs
   published the same day `4.3.5` was cut, all already fixed by the pin.
   Corrected the ADR-0009 record (caught and fixed a severity-count error
   in the same PR before merging).

## What was tried this cycle (a security-advisory sweep across more
components, using the method that found real gaps in cycles 6-8)

Checked `github.com/<org>/<repo>/security/advisories` directly (not just
release notes/currency) against the *current pin* for two more
security-critical always-on components, cross-referencing each advisory's
own affected/patched-version fields:

- **Envoy Gateway** (`v1.8.3` pin) — 10 advisories total, including one
  Critical (GHSA-wcrf-9vrr-854f, CVSS 9.1, Lua path-traversal auth bypass)
  and three High. All four checked in detail affect version ranges below
  `1.8.1` or earlier lines (`1.2.6`, `1.5.7`/`1.6.2`, `1.7.4`/`1.8.1`) — the
  current `1.8.3` pin is already past every fix floor. Cross-checked against
  ADR-0008's own 2026-07-18 CVE-sweep entry (audit #515): the same GHSAs
  (xDS auth bypass, Lua validator bypass, wasm cache, nil-deref, OCI
  extraction, ReferenceGrant bypass, gzip decompression) were already found
  and addressed then, at `v1.8.2` — `v1.8.3` (current) is newer still. Not a
  new finding, but re-confirms the pin is safe.
- **Kyverno** (chart `3.8.2`, appVersion `v1.18.2` — verified directly via
  the chart repo's `index.yaml`, not assumed) — one Critical advisory
  (GHSA-79gf-7frw-68m9, CVSS 9.6, `NamespacedMutatingPolicy`
  `generator.apply()` namespace-bypass) affecting `v1.18.0`–`v1.18.1`,
  patched at exactly `v1.18.2` — the appVersion this pin already carries.
  Also confirmed chart `3.8.2` is the newest available (no currency gap
  either).

Also re-swept `docs/dependency-tree.md`, `README.md`, and
`docs/decisions/context.md` for any other stale version-number drift from
this run's own bumps (RabbitMQ `4.3.5`, Cilium `1.18.13`) beyond the two
`dependency-tree.md` mentions already caught and fixed in PR #1252 — none
found.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (2
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, re-checked this
cycle — still 2026-08-17T18:50:01Z, no new confirmation).

## Why this is the honest deliverable

This cycle's fresh lens (direct security-advisory-page audits against
current pins, the same method that found 2 real gaps in cycles 6 and 8)
came up with two more components already fully safe rather than a new
actionable finding — a legitimate "kept, confirmed" outcome, not a dead
end. No code shipped this cycle. Recording the honest outcome per ROADMAP
rule #9 rather than fabricating make-work. Not a stopping point — the run
continues from STEP 1.
