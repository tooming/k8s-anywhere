# ADR-0006 — remove stale "Follow-up: wire both bootstraps into `make up`/DR" note

CHARTER **Core Values** §"Docs & dashboards don't drift"; planner gap-analysis
finding, 2026-07-18 — no prerequisites, executor picked up immediately.

The ADR-0006 `## Decision` §Status paragraph ended with "(Follow-up: wire both
bootstraps into `make up`/DR.)" — but both bootstraps are already wired:
`Makefile`'s `up` target calls `$(MAKE) gitlab-tls-bootstrap` (line 187) and
`$(MAKE) grafana-gitsync-bootstrap` (line 191), both between `vault-bootstrap`
and `frontdoor`/root-app sync, and both `.PHONY` targets (`gitlab-tls-bootstrap`
line 371, `grafana-gitsync-bootstrap` line 375) exist and run their respective
scripts. Verified directly against the current `Makefile` (not assumed, per
ADR-0004) before landing this. This was stale-doc drift, not a missing feature:
the ADR's own claim about its still-open follow-up no longer matched the repo's
actual state.

## What changed

- Deleted the stale "(Follow-up: wire both bootstraps into `make up`/DR.)"
  sentence from ADR-0006's `## Decision` §Status paragraph
  (`docs/decisions/adr-0006-grafana-native-git-sync.md`), replacing it with a
  factual statement that both bootstraps are wired into `make up`.
- Added a mechanical recurrence guard: a new bats assertion in
  `tests/bootstrap-seams.bats` ("ADR-0006 does not carry a stale 'Follow-up'
  note about the bootstrap wiring") asserting the ADR text no longer contains
  the literal stale sentence, alongside the existing assertions in the same
  file that already prove both bootstraps are actually wired into `make up`
  — so if the wiring is ever reverted, the existing tests catch that, and if
  someone re-adds the stale prose after a future edit, this new test catches
  that.

`make ci` passes.

## PR

(filled in after PR creation)
