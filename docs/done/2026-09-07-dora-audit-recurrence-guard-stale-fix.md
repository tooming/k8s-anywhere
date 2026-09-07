# Fix a stale bats-coverage description in dora-audit-readiness.md's Stateless component criticality tiers

JANITOR-fallback cleanup (executor STEP 6b), continuing the
post-simplification re-orientation sweep (#1498, #1499, #1500, #1502,
#1503) into one more prose inaccuracy in the same file.

## What was found

The "Stateless component criticality tiers" section's own "Recurrence
guard" note claimed: "`tests/dora-audit-readiness.bats` asserts this table
exists and names Cilium and Traefik specifically — the two components
tiered P0 here." Checked directly against the real test file: it only ever
asserted `| Traefik | **P0**'` (line 25-26,
`@test "criticality tiering names Traefik at P0..."`) — there is no, and
never was in this test's current form, a Cilium-specific assertion. Cilium
was removed entirely 2026-09-07 (ADR-0014, no replacement) and the table's
own P0 row for CNI/NetworkPolicy enforcement was correctly updated to "k3s's
bundled Flannel + kube-router" — but this one description line about what
the *test* checks was left describing the old table's shape, not the real
test.

## What was fixed

Corrected the Recurrence-guard note to describe what the test actually
asserts (Traefik only), with a note on why no test change was needed when
Cilium's row changed (the test never covered that row specifically).

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction, no code/manifest/test touched. Verified directly against
`tests/dora-audit-readiness.bats`'s real assertions before writing the
replacement text.

## PR

https://github.com/tooming/k8s-anywhere/pull/1504 (chore/dora-audit-recurrence-guard-stale-fix)
