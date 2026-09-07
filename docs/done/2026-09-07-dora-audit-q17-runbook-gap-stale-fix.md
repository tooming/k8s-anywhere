# Fix a stale "gap" claim in docs/dora-audit-readiness.md's Q17 (exit-runbook coverage)

JANITOR-fallback cleanup (executor STEP 6b), a fourth distinct finding this
run's current gated-lane streak, using the same technique that found
#1486/#1489: cross-checking a doc's own "still open" claims against the
mechanically-enforced current state rather than trusting the prose.

## What was found

`docs/dora-audit-readiness.md`'s Q17 ("Is there an exit strategy per
critical third-party dependency?") **Gap** section claimed: "Several newer
register rows (Velero, Trivy Operator, Kargo, Harbor, Oracle Cloud
Infrastructure, k3s, moto, ACK S3 controller, KRO, s3manager, Vault,
External Secrets Operator) don't yet have one [an exit runbook] — a real,
separately-scoped gap."

This was true when written (2026-09-06, per the note's own dating elsewhere
in this run's history) but had since been closed: `docs/dependency-exit-
runbooks.md` gained a "Remaining single-tool rows (the final thirteen)"
section the same day covering exactly those twelve tools plus Kyverno.
Verified directly this session: `make dependency-exit-runbooks-sync-check`
(wired into `make ci`'s `drift` job) currently reports "✓ every concentration
group and every register row has a matching exit-runbook mention" — a
mechanically-enforced, currently-passing fact, not an assumption.

## What was fixed

Rewrote the Q17 Gap section to state the real, current, closed status —
every one of the register's 21 current rows has a runbook entry, mechanically
enforced by `make ci` — with a citation to the 2026-09-06 sweep that closed
it and an honest note that the old text was accurate when written, just
stale by the time this correction landed. The RabbitMQ/Valkey/KEDA
removed-dependency note (still accurate) was kept.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction, no code/manifest/test touched. The "21 current rows, all
covered" claim was verified against `make dependency-exit-runbooks-sync-
check`'s own live output in this session, not assumed.

## PR

(backfilled after PR creation)
