# ADR fixture with a Removed status

**Status.** Removed 2026-09-07 (fixture — component dropped entirely, no
replacement). This decision record is kept for history; do not treat any
Makefile target named below as still existing.

This ADR references `make bogus-removed-target`, a target the fixture
Makefile does not define — expected to go stale once the component was
removed, same as a **Superseded by** ADR's historical mentions. readme-check
must NOT flag this as drift.
