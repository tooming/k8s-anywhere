# Consolidate the four `dr-chaos-*.sh` scripts' duplicated retry/fail/kill-and-wait logic into `scripts/lib/dr-chaos.sh`

Found live 2026-09-14 (STEP 6b JANITOR-fallback cleanup — cycle 6 of this
run, after PLANNER/ARCHITECT/UPGRADE-DRAFTER-fallback work in cycles 1–5
already exhausted the backlog, dependency-currency, and architect-digest
lanes). `scripts/dr-chaos-argocd.sh`, `scripts/dr-chaos-cert-manager.sh`,
`scripts/dr-chaos-traefik.sh`, and `scripts/dr-chaos-lab-demo.sh` each
hand-rolled a byte-identical `retry()`/`fail()` pair and a near-identical
"capture the matching pod's current UID, delete it, poll for a new Ready
pod" sequence — confirmed directly via `diff`, not assumed. Only the final
recovery predicate (ArgoCD sync health / cert-manager issuer chain /
Traefik HTTP probe / lab-demo content check) genuinely differs between the
four scripts. This is the exact same duplication shape this repo already
consolidated twice before — `scripts/lib/kctx.sh` (the KCTX-aware `kubectl()`
wrapper, three callers) and `scripts/lib/confirm.sh` (the type-to-confirm
gate, four callers) — so this cleanup follows that established pattern
rather than inventing a new one.

## What was done

- Added `scripts/lib/dr-chaos.sh` (sourced, not executed) providing
  `dr_chaos_start`, `dr_chaos_fail`, `dr_chaos_retry`, and
  `dr_chaos_kill_and_wait` — the last one wraps the full
  capture-UID/delete/poll-for-new-Ready-pod sequence, taking the
  namespace/selector/timeout/human-readable-label as arguments and setting
  `DR_CHAOS_NEW_POD_NAME` on success (needed by `dr-chaos-lab-demo.sh`'s own
  recovery predicate, which `exec`s into the specific new pod rather than
  probing over HTTP like the other three).
- Rewrote all four `dr-chaos-*.sh` scripts to source the new lib and call
  its helpers instead of re-declaring their own copies. Every script keeps
  its own recovery predicate (`p_argo_healthy`, `p_issuer_chain_ready`,
  `p_http_ok`, `p_content_ok`) unchanged — those are the genuinely distinct
  part of each drill.
- **Behavior preserved exactly**, including every string `tests/dr-guards.bats`
  asserts on (`"no live <label> pod found (selector: ...)"`,
  `"Refusing non-interactively"`) — verified by re-running the existing 8
  `dr-chaos-*` bats assertions, all still green.
- Added a recurrence guard (mirroring `tests/kctx-lib.bats`'s own analogous
  check for the KCTX pattern): `tests/dr-guards.bats` now also asserts no
  `dr-chaos-*.sh` script re-inlines its own `retry() {` function, and that
  every one sources `lib/dr-chaos.sh`.

Net effect: the four scripts shrank from 342 combined lines to 235 (plus the
new 79-line shared lib, since the real win is a single source of truth for
the repeated logic, not raw line count) — a future format tweak to the
retry-loop shape or the FAILED banner now needs one edit instead of four.

## Validation

`make ci` — full local run, green, including the two new guard-test
assertions and all 8 pre-existing `dr-chaos-*` bats tests (which actually
exercise the refactored code path for real: `DR_ASSUME_YES=1` runs each
script against this clusterless environment's unreachable `kubectl`, hits
the new `dr_chaos_kill_and_wait`'s `before_uid` check, and correctly fails
with the exact same "no live ... pod found" message as before). Not merely
a lint-level check — this is the closest thing to a functional test this
clusterless environment can run against live-cluster code.

## PR

(chore/dr-chaos-lib-consolidation) — autonomous scheduled executor run,
cycle 6, STEP 6b JANITOR-fallback.
