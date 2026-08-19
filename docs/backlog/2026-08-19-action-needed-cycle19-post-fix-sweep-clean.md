# [Action needed] Now/next still gated; post-fix sweep clean (cycle 19)

**Date:** 2026-08-19
**Cycle:** 19th cycle this run

## What's blocked

Unchanged: the "Now / next" lane holds the same three items re-confirmed
every cycle this run — the two GitLab→Forgejo migration items (deliberately
un-picked-up per their own investigation notes: a real auth-model finding,
SSH deploy keys vs. HTTPS+PAT, makes a blind rename unsafe, and `make up`'s
bootstrap sequence needs a live-verified rewrite) and the legacy capstone
`Deployment` removal on issue #633 — re-checked again this cycle,
`updated_at` still 2026-08-17T18:50:01Z, no new confirmation comment.

## What shipped this run's cycles 17–18 (context for this record)

Two real, merged fixes came out of a fresh lens this run hadn't tried yet —
auditing whether the repo slugs `docs/dependency-register.md` and
`routines/architect.prompt.md` cite actually resolve/track the right
component, rather than re-running the same GHSA-sweep-per-component pattern
prior cycles (9–16) had already exhausted:

- **PR #1264** — `github.com/Deuxfleurs/garage` was a dead 404; the real org
  is `deuxfleurs-org`. Fixed in both files, ADR-0002 re-evaluation logged, a
  pinned-value regression guard added.
- **PR #1265** — `routines/architect.prompt.md` STEP 1 still tracked the
  decommissioned Artifactory (`jfrog/charts`) instead of Harbor
  (`goharbor/harbor-helm`), three weeks after ADR-0024 replaced it. Fixed,
  guard added to the existing `tests/no-artifactory.bats`.

## What was tried this cycle (came up clean — no third bug, no new gap)

Continuing the same "does the cited thing actually match reality" lens to
its natural conclusion, plus a few adjacent checks:

- **Every remaining `github.com/<owner>/<repo>` slug** in
  `docs/dependency-register.md` (29 total) and `routines/architect.prompt.md`
  STEP 1 (17 total, post-fix) resolves via `git ls-remote` — no third dead
  link or wrong-component reference exists.
- **Untested-script sweep**: every file under `scripts/*.sh` is referenced
  by at least one `tests/*.bats` file — no coverage gap.
- **Kiali** (on-demand, last GHSA-swept 2026-08-04): re-checked directly —
  `github.com/kiali/kiali`'s newest tag is `v2.30.0`, exactly this lab's
  current chart pin; zero published advisories on the correct repo.
- **TiDB** (last touched 2026-08-06, ADR-0032 authored): `github.com/pingcap/
  tidb/security/advisories` lists exactly one advisory
  (GHSA-4whx-7p29-mq22, High, published 2022-05-26) — four years old,
  irrelevant to the current `v8.5.x` pin.
- **PLANNER re-check**: still only 2 open issues (#633, #1229), both already
  fully labeled standing `[Action required]` gates; zero ungroomed intake;
  `docs/roadmap/incoming/` still empty.
- **ARCHITECT re-check**: zero unchecked `- [ ] 🟡` items exist to RFC.
- **UPGRADE-DRAFTER**: already spent its one-PR-per-run cap earlier this run
  (`upgrade/rabbitmq-4.3.4-to-4.3.5`, PR #1250) — not re-attempted.
- **This week's industry digest** (`docs/industry/2026-W34-digest.md`)
  already exists and reflects state through 2026-08-18; nothing this run's
  cycles 17–19 found rises to "worth a mid-week refresh" over the routine
  cadence.

## Why this is the honest deliverable

Two real fixes already landed this run from this exact lens (cycles 17–18);
pushing the same lens further and adding two adjacent checks (script
coverage, two more on-demand-component GHSA re-verifications) came up clean.
Recording that honestly per ROADMAP rule #9 and `executor.prompt.md` STEP
6b/STEP 8 rather than fabricating a third fix. Going straight back to STEP 1
for the next cycle — this is not a stopping point for the run.
