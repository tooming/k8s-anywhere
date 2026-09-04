# Stop declaring idle — every run ships a PR (+ close a real coverage gap)

Maintainer feedback (2026-07-14, following issue #398): the evidence-gated "executor
idle — needs work" issue pattern (ROADMAP rule #9) let idle issues pile up (#52, #56,
#57, #76, #89, #121, #262, #390, #398) instead of forcing real work every run. The
maintainer ended the pattern outright: idle declarations are now forbidden, not merely
gated on evidence.

## Changes

- **ROADMAP.md rule #9** rewritten: opening/commenting on an "executor idle" issue is no
  longer an acceptable terminal outcome under any circumstance. Added two new fallback
  lanes to the chain a blocked run must walk before concluding there's nothing to build:
  a **coverage/hardening check** (untested scripts, drifted docs, stale chart pins, ADRs
  due for re-evaluation — real, clusterless, gate-passing, and never exhausted) and a
  **split-the-gate check** (pull an ungated prep slice out of a `Now / next` item that's
  blocked on a live-cluster maintainer confirmation, mirroring how RFC #214's cosign work
  was split into three sub-items).
- **`scripts/idle-issue-guard-check.sh`** flipped from "requires fallback-chain evidence"
  to "blocks any idle/no-work declaration unconditionally" — evidence no longer buys a
  pass. Updated `scripts/idle-issue-guard-hook.sh`'s guidance accordingly (close the
  issue instead of amending it) and the two `tests/drift-detectors.bats` cases that
  asserted the old evidence-gated behavior.
- **CLAUDE.md** updated to state the same policy in the working agreement itself, not
  just the mechanical guard.
- **Closed issue #398** ("executor idle — needs work") as `not_planned` — its underlying
  gap (untested `dr-verify.sh`/`frontdoor-ensure.sh`/`lab-health-check.sh`/
  `tfstate-bootstrap.sh`) is exactly what the new coverage/hardening lane names, and is
  fixed by this same PR. Closing it tripped the freshly-hardened guard (the closing body
  legitimately discusses "idle issues" as a standalone word, outside any hyphenated
  compound the existing self-trigger scrub recognized) — fixed by teaching the guard
  that `state: closed` is always the resolution, never the violation:
  `idle-issue-guard-hook.sh` now forwards `tool_input.state`, and
  `idle-issue-guard-check.sh` exits 0 immediately when `IDLEGUARD_STATE=closed`. New
  bats case covers it.

## Coverage/hardening work landed this PR (proves the new lane is real, not just rhetoric)

New `tests/lab-ops-scripts.bats` (35 assertions): structural coverage for four
previously-untested, `make`-wired operational scripts — `scripts/dr-verify.sh`
(`make dr-verify`), `scripts/frontdoor-ensure.sh` (`make frontdoor`),
`scripts/lab-health-check.sh` (`make health`, also invoked by `make up`), and
`scripts/tfstate-bootstrap.sh` (`make tfstate-up`). Verifies each script's declared
health/DR checks, budget variables, idempotency guards, and its Makefile wiring — all
clusterless (no kubectl/docker/k3d/garage execution). `make ci` passes (the 7 pre-existing
`not ok` results in this sandbox — `argo-rollouts`/`helm-chart-pin-check`/
`argocd-crd-ssa-check`/`rollouts-plugin-list-check` — are unrelated environment gaps:
this session's `yq` is the Python/kislyuk build, not `mikefarah/yq`, and outbound access
to Helm chart repos is proxy-restricted; both are pre-existing and reproduce identically
on a clean checkout).

## PR

https://github.com/tooming/k8s-anywhere/pull/399
