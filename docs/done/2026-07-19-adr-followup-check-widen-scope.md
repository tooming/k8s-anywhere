# Widen adr-followup-check to also cover CHARTER.md and WAYS-OF-WORKING.md

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b.)

This run's earlier `adr-followup-check` guard (`docs/done/2026-07-19-adr-followup-check.md`,
PR #568) was scoped only to `docs/decisions/adr-*.md`, closing the recurrence gap for
the ADR-0006 stale follow-up note. But this same run's CHARTER.md read-through (PR #571)
found the *identical* bug class one file over: CHARTER.md's "Event-driven autoscaling"
entry carried its own unchecked "A follow-up wires ..." promise for KEDA, stale for the
same reason (the work shipped, the prose never got updated) — a case the guard's
`docs/decisions/`-only scope didn't catch because it isn't an ADR.

Widened `scripts/adr-followup-check.sh` to scan `docs/decisions/adr-*.md`, `CHARTER.md`,
and `docs/WAYS-OF-WORKING.md` (whichever of the three exist) for the literal
`Follow-up:` string — every governance doc that carries binding, hard-to-verify prose,
not just ADRs. Updated:

- `scripts/adr-followup-sync-hook.sh`: PostToolUse hook now also reacts to edits of
  `CHARTER.md` / `docs/WAYS-OF-WORKING.md`, not just `docs/decisions/*`.
- `Makefile`'s `adr-followup-check` target description.
- `tests/drift-detectors.bats`: split the single drift fixture into `drift-adr` and a
  new `drift-charter` case (asserting the failure output actually names `CHARTER.md`,
  not just any file), plus an in-sync fixture that now includes both an ADR and a
  CHARTER.md.
- `tests/fixtures/adr-followup-check/`: rebuilt as `in-sync/`, `drift-adr/`,
  `drift-charter/`.

Script/target/hook file names kept as `adr-followup-*` (not renamed) — the underlying
bug class and mechanism are identical, only the file scope grew; renaming would touch
`Makefile`/`ci.yml`/`.claude/settings.json` for no behavioral gain.

Behavior-preserving for every previously-passing case (docs/decisions/ scanning is
unchanged); this only adds two new file scopes. Verified directly (ADR-0004) that the
real repo's `CHARTER.md` and `docs/WAYS-OF-WORKING.md` are currently clean before
landing this. `make ci` passes.

## PR

[#573](https://github.com/tooming/k8s-anywhere/pull/573)
