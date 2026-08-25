# docs: log the Kargo egress NetworkPolicy port/namespace-mismatch incident (PR #1323)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's ninth cycle. "Now / next" remains fully gated (issue
#633, unchanged) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER were re-confirmed unchanged from cycles 3–4. **No prerequisites —
executor may pick up immediately.**

## The gap — a self-caught inaccuracy, not just a missing row

Cycle 5 (PR #1329) logged the Envoy Gateway xDS control-plane connectivity
incident, and its own text referenced "the ... 2026-08-25
kargo-egress-port/namespace [row] above" as an existing citation — but no
such row was ever actually added; only the *follow-up* bug (xDS
connectivity) got logged, not PR #1323's own primary fix (the Kargo egress
NetworkPolicy's wrong namespace selector + wrong port). This means a
previously-merged PR of mine contained a dangling, inaccurate
cross-reference — a small but real violation of the "verify before
asserting" discipline this repo holds itself to. Caught it while re-checking
issue #633's history this cycle, not by any external report.

## The fix

Added the missing row (2026-08-25, P1) for PR #1323's actual primary fix:
`allow-kargo-egress-registry.yaml` selected the `harbor` namespace directly
(should have been `envoy-gateway-system`, since Harbor is only reachable via
the shared Gateway) and listed the gateway Service's ports (80/443) instead
of the envoy-proxy pod's actual containerPorts (10080/10443) — the same
Service-port-vs-pod-port footgun already documented in the 2026-08-07
`harbor` ingress row. This is now correctly the **fourth** occurrence of that
exact footgun class in this repo, not the third as the xDS row's original
citation implied before this fix. The xDS row's own "above" reference is now
accurate, retroactively fixing the earlier inaccuracy without needing to
re-edit that row.

New matching bats assertion in `tests/incident-log.bats`.

`make ci`: green (full local run including real `bats`).

## PR

<!-- filled in after opening the PR -->
