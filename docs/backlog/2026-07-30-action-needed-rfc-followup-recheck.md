# [Action needed] Now/next still gated; RFC follow-up + stale-status grep sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on [#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did (this session)

Merged three real PRs so far: [#896](https://github.com/tooming/k8s-anywhere/pull/896)
(stale DORA metrics refresh), [#897](https://github.com/tooming/k8s-anywhere/pull/897)
(prior cycle's action-needed record), and
[#898](https://github.com/tooming/k8s-anywhere/pull/898) (fixed ADR-0026's stale
"cloud backend not yet built" claim — found via a systematic ADR audit-gap sweep).

## This cycle's fresh angles (both clean)

1. **Stale-status phrase sweep, extended.** Grepped `CHARTER.md` and `ROADMAP.md`
   for the same bug class that produced #898 (`not yet built/implemented/wired`,
   `in progress`, `coming soon`, `planned`, `on track`). The one ROADMAP hit
   ("Harbor cutover is in progress") is inside an already-completed `[x]` item's
   original task description (historically accurate at time of writing, before
   the later full Artifactory decommission) — not a live status claim, no fix
   needed.
2. **RFC follow-up check.** Spot-checked the 10 RFC issues ROADMAP's "Groomed ↗"
   entries cite (#206/#214/#215/#287/#288/#289/#358/#377/#580/#611) for
   unresolved follow-up. Verified #611's GitHub Actions major-version bump
   RFC actually landed (`.github/workflows/*.yml` pins confirmed at
   `checkout@...#v7.0.1`, `cache@...#v6.1.0`, `github-script@...#v9.0.0`,
   `setup-terraform@...#v4.0.1` — matches or exceeds the RFC's targets); #580
   (DORA metrics) and #377 (Oracle first cloud backend) are both closed with
   their full acceptance criteria genuinely shipped (re-confirmed against
   `scripts/dora-metrics.sh` and `infra/live/oracle/` existing on disk). No
   unresolved follow-up found on any checked RFC.
3. **Extra due-diligence:** repo-wide grep for stray `artifactory` references
   outside `docs/done/`/`docs/decisions/` (historical record, expected) turned
   up only the intentional `scripts/readme-check.sh` Superseded-ADR exemption
   added earlier this run — decommission remains fully clean.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
