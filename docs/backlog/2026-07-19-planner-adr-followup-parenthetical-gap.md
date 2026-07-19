# Planner run — 2026-07-19 (executor fallback)

## Trigger

The executor's own "Now / next" lane was fully gated this run: all five remaining
unchecked ROADMAP items (`auto/cosign-enforce-flip`, `auto/o4-ci-rejection-gate`,
`auto/harbor-capstone-rewire`, `auto/harbor-artifactory-decommission`,
`auto/capstone-deployment-removal`) carry maintainer-confirmation or
live-cluster-verification prerequisites (a `.sig` tag push confirmed live, a Harbor
footprint measurement on the live cluster, an exercised end-to-end Kargo promotion)
that cannot be checked from a clusterless remote session — each item's own executor
note says to skip it if unverifiable this run. No open GitHub issues, no pending
`docs/roadmap/incoming/` architect items. Falling back to the planner role per
`executor.prompt.md` STEP 6b.

## Gap analysis

Dispatched a read-only research pass comparing CHARTER.md's Objectives (O1-O7),
Core Values, and Target end-state against the actual repo state, covering: O3's
`make dr-restore` timed-bats measurement, O6's `make capstone-demo` wall-clock
target, ADR "Follow-up:"-style stale promises, untested scripts, README/
dependency-tree drift, and ADR re-evaluation-log staleness.

Six of seven checks came back "already covered, no action" — O3 and O6 both have
real, wired, bats-covered budget-enforcing targets; no untested scripts remain;
README/dependency-tree have no stale "Planned" rows; ADR re-evaluation logs use
event-triggered (not calendar-based) re-checks so none are overdue; the ADR count
in CLAUDE.md matches the real highest-numbered file (30).

One real gap surfaced: `scripts/adr-followup-check.sh` is a mechanical guard
against exactly one stale-promise shape — the capitalized literal `Follow-up:` —
per its own header comment, added after ADR-0006 and CHARTER.md both went stale
that way undetected. A second, syntactically different shape has the identical
problem and the guard doesn't catch it: five table rows across
`docs/decisions/adr-0028-cert-manager-tls-lifecycle.md` (lines 192-194) and
`docs/decisions/adr-0029-keda-event-driven-autoscaling.md` (lines 184-185) still
carry a `(follow-up item)` annotation for work that has already shipped and is
already bats-covered:

- ADR-0028's HTTPS `:443` listener, wildcard `Certificate`, and `:8443` frontdoor
  mapping — all three verified present (`gitops/network/gateway.yaml`,
  `gitops/network/certificates/wildcard-certificate.yaml`,
  `scripts/bluegreen-frontdoor.sh`/`frontdoor-ensure.sh`) and covered by
  `tests/frontdoor-https.bats`.
- ADR-0029's cert-manager webhook TLS wiring and `ScaledObject`/
  `TriggerAuthentication` demo — both verified present
  (`gitops/platform/keda.yaml`'s `certManager` block,
  `gitops/data/demo/keda-scaling/`) and covered by `tests/keda.bats` /
  `tests/keda-scaledobject.bats`.

This is the same undetected-drift failure mode the guard exists to prevent,
recurring in a second syntactic shape the original fix didn't anticipate.

## Item added to ROADMAP.md ("Now / next")

- **Fix stale `(follow-up item)` markers in ADR-0028/ADR-0029 + widen
  `scripts/adr-followup-check.sh` to catch the parenthetical form**
  (`auto/adr-followup-parenthetical-form`) — corrects the five stale table cells
  and widens the guard's grep pattern to also catch `(follow-up item)`, with a new
  drift fixture + bats case so the guard now self-detects both shapes of the same
  stale-promise class going forward. No prerequisites; buildable immediately.

## Not groomed / no action

- No open GitHub issues to groom (intake queue empty).
- No pending `docs/roadmap/incoming/` architect items to absorb.
- The five gated Now/next items above are left as-is; each already documents its
  own unblocking condition and none of it is verifiable from this clusterless
  session this run.
