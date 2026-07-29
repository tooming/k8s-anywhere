# [Action needed] Now/next still gated; two real fixes already landed this run, this cycle's fresh angles came up dry

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already did

This is the fourth cycle of the current executor run. The first three each
produced a real deliverable via the STEP 6b fallback chain:

1. **Planner (gap analysis) → PR [#865](https://github.com/tooming/k8s-anywhere/pull/865).**
   Found and fixed a verified doc-drift gap: `docs/dependency-tree.md`'s
   mermaid integration graph had zero `cert-manager`/`KEDA` nodes despite two
   ROADMAP items claiming the diagram was updated when those components
   landed. Added the missing subgraphs + edges, sourced only from prose
   already documented in the file (ADR-0004-compliant, no invented facts).
2. **Doc-drift-author** executed that fix directly (same PR — the finding
   matched its contract exactly, so no separate plan-PR indirection was
   needed).
3. **Janitor → PR [#867](https://github.com/tooming/k8s-anywhere/pull/867).**
   Found and fixed a real, already-manifesting footgun: `tests/hook-scripts-coverage.bats`
   had grown to 68 `@test` blocks across 18 unrelated hook scripts — already
   past the size every other frozen monolith in this repo
   (`tests/securitycontext.bats`, `tests/drift-detectors.bats`) had reached
   before hitting the "shared monolith multiple PRs append to" collision
   footgun and getting frozen. Applied the same mechanical guard (snapshot
   check + PostToolUse hook + `make ci`/GitHub Actions wiring + bats
   coverage) that already protects the other three monoliths.

## This cycle's fresh angles (both came up dry, on purpose — not fabricated)

- **Architect lens:** searched for an un-RFC'd 🟡 item in ROADMAP.md — none
  exist; every 🟡 entry currently in the file is already struck through
  (`~~🟡 …~~`), meaning already resolved into a binding RFC.
- **Upgrade-drafter lens — KRO `0.9.2` → `0.9.3`:** re-attempted verification
  beyond what the prior cycle's note
  ([`2026-07-29-action-needed-kro-0-9-3-unverifiable.md`](2026-07-29-action-needed-kro-0-9-3-unverifiable.md))
  found. Confirmed via `WebFetch` that `kubernetes-sigs/kro`'s GitHub
  Releases page lists `v0.9.3` as its latest tag. But this repo pins
  `ghcr.io/kro-run/kro` chart `kro` — a *different* registry path — and
  `WebFetch`ing that org's GHCR package page shows a `kro/kro` package with
  version tags only up to `0.4.1`, nothing resembling `0.9.x` at all. That's
  either a different package under the same GHCR org (image vs. chart) or a
  stale page — genuinely ambiguous from outside the sandbox's blocked GHCR
  access (`ghcr.io/token?...` still returns `DENIED` from this session too,
  confirmed by direct retest). Bumping on this evidence would repeat the
  exact "git tag exists before the chart artifact does" mistake this repo
  already caught once (issue #663, ADR-0008 Re-evaluation log) — correctly
  held back again, not a fresh finding, just a confirmed dead end.
- **ROADMAP.md follow-up-promise sweep:** `scripts/adr-followup-check.sh`
  only scans `docs/decisions/`, `CHARTER.md`, `WAYS-OF-WORKING.md` — not
  `ROADMAP.md` itself. Grepped `ROADMAP.md` directly for `Follow-up:` /
  `follow-up item` — every match is already inside a `[x]`-checked item
  (resolved history), no live unchecked promise found.
- **Triager lens:** only the three standing `[Action required]` issues
  (#631/#632/#633) are open; none need triage (already correctly labeled,
  already the subject of this exact gate).

## What would unblock further work

Unchanged: a maintainer-confirmation comment on #631/#632/#633 is the only
thing that reopens the "Now / next" lane. Everything buildable without it has
either already landed (this run: 2 real PRs) or been correctly, repeatedly
verified as not-yet-actionable (KRO 0.9.3).

This is an autonomous scheduled run (executor routine, STEP 6b final
fallback). Per STEP 8 the run continues to the next cycle after this PR
merges — this is not a stopping point.
