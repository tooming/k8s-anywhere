# docs: log the vault-unsealer wedged-loop incident (PR #884)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's sixth cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes found nothing new this cycle
either. **No prerequisites — executor may pick up immediately.**

## The gap

`gitops/vault/unsealer.yaml`'s own header comment records a real, already-
fixed incident: on 2026-07-29 (the same cluster-wide network outage as the
already-logged Cilium row), `vault-0` restarted and came back sealed, and
the unsealer's own `vault status` call — with no timeout — hung on the dead
connection, wedging its `while true` loop forever. The container never
crashed, so kubelet had no signal to restart it; Vault stayed sealed for
**4+ days**, silently breaking every `ExternalSecret` refresh cluster-wide.
`docs/dora-audit-readiness.md`'s own "Stateless component criticality
tiers" table already cites this as a "documented real incident" for Vault's
P1 classification — but it was never actually copied into
`docs/incident-log.md`'s own "Real incident history" table, the artifact
that exists specifically to hold this kind of record.

## The fix

Added a new row (2026-07-29, **P1**) right after the already-logged
`artifactory` NetworkPolicy row — both were fixed by the same PR #884
(`fix(networkpolicy,vault): unblock Artifactory bring-up + harden
vault-unsealer`), so this is a second, distinct incident from that same
session, not a duplicate. Cites the fix exactly as documented in the
manifest's own comment: a `timeout` bounding each `vault` call, plus a
heartbeat file + liveness probe so kubelet can detect and restart a wedged
loop. Added a matching bats coverage test.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1315
