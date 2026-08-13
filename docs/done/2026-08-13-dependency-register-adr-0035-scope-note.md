# Fix stale ADR count/superseded-list in dependency-register.md's Scope note

**JANITOR-fallback cleanup (STEP 6b, category 3 — dead or stale matter).** No
Now/next ROADMAP item was buildable this cycle: every unchecked item (the three
remaining sequential Forgejo-migration items, the `verifyImages` Enforce flip, the
O4 CI-rejection gate, and the legacy capstone `Deployment` removal) is gated on
either a live-cluster verification step this remote session cannot perform, or on
one of the two standing `[Action required]` issues (#631, #633) — both re-checked
directly, neither carries a new confirmation comment since 2026-08-11. PLANNER,
ARCHITECT, UPGRADE-DRAFTER, and TRIAGER all came up empty too (no ungroomed
issues/`docs/roadmap/incoming/` files, no open `adr-audit` issues, every
`gitops/platform/*.yaml` chart pin already the newest upstream tag as of the prior
run's same-day sweep, both open issues already fully labeled) — full reasoning
walked fresh this cycle before falling to JANITOR.

## What was stale

`docs/decisions/README.md` lists 35 ADRs (ADR-0001–ADR-0035), with ADR-0033
superseded by ADR-0035 (2026-08-11, the GitLab → Forgejo migration ADR). But
`docs/dependency-register.md`'s "Scope note" section — which explains exactly how
many ADRs the register's table covers and why — was never updated past its
2026-08-07 authoring day: it still said "34 ADRs... (ADR-0001–ADR-0034)" and named
only two Superseded ADRs (ADR-0010, ADR-0011), missing ADR-0033/ADR-0035 entirely.

Recomputing the note's own math against the *actual* table (32 tool rows, 24
distinct ADRs cited) also surfaced a **second, older** inconsistency predating
ADR-0035: the note claimed "the remaining 22 ADRs name 24 distinct third-party
tools," but 22 was already wrong even before ADR-0035 existed — the 2026-08-07 edit
that added ADR-0033/ADR-0034 (and their 8 new table rows: GitLab + the seven LGTMP
observability-internals tools) bumped the ADR total from 32 to 34 and updated the
top of the note, but never propagated that +2 into this second paragraph's counts.
It also undercounted which ADRs decide more than one tool at once: ADR-0027
(Oracle Cloud Infrastructure + k3s) does, same as ADR-0001 and ADR-0012, but wasn't
named alongside them.

## The fix

Rewrote the Scope note's two paragraphs with the correct, hand-verified numbers:

- 35 ADRs indexed (ADR-0001–ADR-0035).
- Two ADRs fully excluded per the "only the replacement is listed" convention:
  ADR-0010, ADR-0011.
- ADR-0033 called out as a **third, transitional** case — superseded by ADR-0035
  but *not* excluded, because the superseded tool (GitLab) is still the live,
  running component; the table keeps citing ADR-0033 until the migration
  completes, and ADR-0035 has no row of its own yet.
- 33 ADRs remain after that exclusion; 8 are policy/posture ADRs excluded from the
  table (unchanged list).
- Of the remaining 25, 24 have an actual table row (naming all 32 tool rows,
  correctly attributing the three ADRs that name more than one tool at once —
  ADR-0001, ADR-0012, ADR-0027 — plus ADR-0034's seven at once); the 25th,
  ADR-0035, is the transitional exception with no row of its own.

No table rows, criticality tiers, or "Last reviewed" dates were touched — this is
pure prose accuracy in the note that explains the table, not a change to the
table's content itself. `docs/dependency-concentration.md`'s own "32 tool rows"
citation was checked and is already consistent — no change needed there.

`make ci` confirmed green before and after (this file isn't covered by any
mechanical drift guard yet — the register's own "Keeping this in sync" section
already flags that as a possible future guard, premature to build for a single
observed drift).

## PR

https://github.com/tooming/k8s-anywhere/pull/1174
