# Fix `dr-network-partition.sh`'s `--wait=false` race condition (false-positive self-heal risk)

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's "every bugfix must prevent
recurrence" — found live during an executor self-review pass, 11th cycle this run,
while adversarially re-reviewing this run's own earlier work (`dr-network-partition.sh`,
PR #1227, merged two cycles ago) after PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER/JANITOR's usual fallback-chain checks all found nothing further this cycle
(Now/next lane still fully gated).

## What was found

`scripts/dr-network-partition.sh` deleted the target NetworkPolicy with `kubectl delete
networkpolicy "$POLICY" -n "$NAMESPACE" --wait=false`, then immediately started a
self-heal poll loop re-checking for the object's existence. `--wait=false` returns as
soon as the delete request is *accepted* by the API server, not once it's *completed* —
the poll loop's very first iteration could then still observe the not-yet-deleted
object and report a false-positive instant "self-heal confirmed" (`ELAPSED` near 0s)
without the drill ever actually observing a real delete-then-restore cycle.

Root cause: `--wait=false` was mechanically copied from `dr-chaos.sh`'s pod-delete
pattern without checking whether the reason it's needed there (avoiding a block for a
pod's `terminationGracePeriodSeconds`) applies to a NetworkPolicy too. It doesn't — a
NetworkPolicy is a plain API object with no grace period, so the default `--wait=true`
(kubectl blocks until the object is confirmed gone) is both correct and effectively
instant here. This is the same failure-mode *class* `dr-chaos.sh`'s own commit history
documents (a command returning success doesn't mean the underlying state change is
actually complete), just a different root cause — a footgun in copying a pattern
without re-verifying its rationale still applies to the new context.

## Fix

Removed `--wait=false` from the delete command (using kubectl's default `--wait=true`
behavior instead), so the delete blocks until the NetworkPolicy is confirmed gone
before the self-heal timer (`START=$SECONDS`) begins — the elapsed time measured is
now genuinely "time from confirmed-deleted to confirmed-restored," not "time from
delete-request-issued (maybe not yet processed) to confirmed-restored."

**Mechanical guard** (CLAUDE.md's "every bugfix must prevent recurrence"): added
`tests/dr-network-partition.bats` assertion `"dr-network-partition.sh does NOT use
--wait=false on the NetworkPolicy delete"`, checking the delete command's own block
for the flag's absence — a future edit reintroducing it (e.g. copying another
pod-shaped pattern without re-checking) fails this test immediately. Also updated the
adjacent "polls for re-existence" test, which previously (incorrectly) asserted
`--wait=false`'s *presence* as expected structure — it now only asserts the poll-loop
wiring, since asserting the bug's own signature as "correct structure" would have
actively defeated the new guard.

## Verification

This remote clusterless session cannot execute the drill against a real cluster to
observe the race empirically (ADR-0004, same caveat as every DR-script addition in
this repo) — the finding is a structural/logical review of the script's own command
sequencing (kubectl's documented `--wait` semantics: `false` returns on request
acceptance, `true`/default blocks until confirmed absence), not a reproduced live
failure. `make ci` passes: full local suite green (bats/shellcheck installed this
session via `apt-get`), including the new recurrence-guard assertion and the full
17-assertion `tests/dr-network-partition.bats` file.

## PR

https://github.com/tooming/k8s-anywhere/pull/1232
