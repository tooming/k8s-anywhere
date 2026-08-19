# [Action needed] Now/next still gated; O2 coverage-guard lead was a false positive, caught before shipping

**Date:** 2026-08-19
**Cycle:** 4th cycle this run

## What was shipped this run so far (for context)

1. PR #1243 — cycle 1's honest record after the full STEP 6b fallback chain
   came up empty.
2. PR #1244 — cycle 2's JANITOR fallback: a real footgun in
   `scripts/prune-stale-branches.sh` (kept any branch sharing history with
   `main` forever, with no way to detect an abandoned push whose PR creation
   itself failed). Fixed with a new time-gated ORPHANED class + 4 bats tests.
3. PR #1245 — a same-run ADR-0004 self-correction: PR #1244's `docs/done/`
   record wrongly claimed two orphaned branches were deleted; the deletion
   attempt actually failed (403, no branch-delete permission), caught via
   direct `git ls-remote` verification and corrected before it could stand
   as a false "done" claim in merged history.
4. PR #1246 — cycle 3's honest record: a different-lens sweep (ADR
   follow-up-promise grep, PR-creation-500 root-cause check) came up empty.

## What was tried this cycle (a genuinely new lens, but a dead end — caught before merging)

A recon sweep across five new lenses (script/test coverage, Makefile target
coverage, ADR re-evaluation staleness, CHARTER objective date pressure,
sidecar-image register gaps) flagged what looked like a strong finding:
CHARTER **Objective O2** ("Default-deny + PSS-restricted everywhere", due
2026-09-30) states *"Measured by: `tests/networkpolicy.bats` +
`tests/securitycontext.bats` cover every namespace in `gitops/`"* — and
neither `securitycontext-tests-check.sh` nor `networkpolicy-tests-check.sh`
(the two scripts actually wired into `make ci`) enforce that claim; they're
anti-monolith structural guards, not coverage guards. This looked like the
identical shape of gap `scripts/o5-dashboard-coverage-check.sh` closed for
Objective O5 on 2026-08-13.

Built `scripts/o2-namespace-coverage-check.sh` mirroring the O5 precedent
exactly (namespace discovery + per-namespace coverage assertion, wired into
`Makefile`/`ci.yml`/a new bats file), validated it locally, then ran the
**full** `bats tests/` suite (not just the new file) before committing —
which is what caught the problem: `tests/drift-detectors.bats` already has
`"every PSA-labelled namespace has securitycontext test coverage (O2
recurrence guard)"` and `tests/networkpolicy.bats` already has `"every NP
overlay dir has a per-scope networkpolicy-<ns>.bats file (O2 recurrence
guard)"` — both explicitly closing `ROADMAP auto/o2-pss-coverage-loop` and
`auto/o2-np-coverage-loop` per their own inline comments, and both already
run on every `make ci` via `scripts/test.sh`'s `bats tests/`. **O2's
"Measured by" promise is already fully, mechanically enforced** — just
implemented as embedded bats assertions inside the two named files rather
than a separate top-level drift-check script, unlike O5 which genuinely had
nothing. Discarded the new script/Makefile/workflow/bats changes rather
than ship duplicate machinery (git-reverted before any commit).

**Recorded here so a future cycle's fallback sweep doesn't re-discover and
re-build this exact same false lead** — the recon-agent pattern that
surfaced it (grep CHARTER's Objectives for "Measured by" claims, cross-check
against `make ci`'s script list) is sound and found a real gap for O5 in the
past, but for O2 specifically the enforcement lives inside the bats files
`grep`-based recon didn't look inside closely enough.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (2 GitLab→Forgejo
migration items un-picked-up per their own investigation notes; capstone
`Deployment` removal gated on issue #633, re-checked this cycle — still
2026-08-17T18:50:01Z, no new confirmation).

## Why this is the honest deliverable

This cycle's fresh lens produced a plausible-looking finding that turned out
to be a false positive, caught by running the full validation suite before
committing rather than trusting the recon in isolation. No code shipped this
cycle — recording the honest outcome (including the near-miss, so it isn't
silently re-investigated) per ROADMAP rule #9. Not a stopping point — the
run continues from STEP 1.
