# Fix stale removed-component examples in docs/incident-log.md's Severity scheme table

JANITOR-fallback cleanup (executor STEP 6b), a seventh distinct finding this
run's current gated-lane streak, extending the same "post-2026-09-06-removal-
wave stale content" sweep that already found #1489 (platform-products.md +
dependency-concentration.md) to `docs/incident-log.md`, a file that same
sweep hadn't yet checked.

## What was found

`docs/incident-log.md`'s "Severity scheme" table — the live, standing P0–P3
definition table this file's own `## How to log a new incident` section uses,
and which `docs/dora-audit-readiness.md`'s Q6/stateless-tier-table and Q7/Q8
sections both cite as evidence — listed the **P2** row's example components
as "Harbor, TiDB, Istio, Longhorn, Kargo's pipeline." Three of those five
(TiDB, Istio ambient mesh + Kiali, Longhorn) were removed from the lab
entirely 2026-09-06 (ADR-0031/ADR-0032, ADR-0012, ADR-0013) — this table is a
current-state reference, not a historical incident-log row (which this
repo's own convention correctly never edits retroactively), so the stale
examples were a real bug, not a preserved historical record.

## What was fixed

Trimmed the P2 row's example list to the two heavy on-demand components that
actually exist today: `(Harbor, Kargo's pipeline)`.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction, no code/manifest/test touched. No bats test asserted the exact
stale text (checked directly via grep before editing), so no test file
needed a matching update.

## PR

https://github.com/tooming/k8s-anywhere/pull/1493 (chore/incident-log-severity-scheme-stale-examples-fix)
