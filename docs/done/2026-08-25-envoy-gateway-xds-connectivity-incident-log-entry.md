# docs: log the Envoy Gateway xDS control-plane connectivity incident (PR #1323)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's fifth cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes were re-confirmed unchanged from
cycles 3–4 (see `docs/backlog/2026-08-25-action-needed-cycle3-*.md` and
`-cycle4-*.md`). **No prerequisites — executor may pick up immediately.**

## The gap

A real, undocumented incident from PR #1323's own investigation (2026-08-25,
merged same day this run started): once that PR's NetworkPolicy and DNS
fixes cleared every other blocker on issue #633, Kargo's Warehouse still
couldn't discover the pushed/signed image. Root cause: the envoy-proxy data
-plane pod can't reach its own xDS control plane (`envoy-gateway`, 148
restarts over 13 days) — `DeltaAggregatedResources gRPC config stream ...
Connection refused`. It never receives listener config, so nothing is
actually listening on its route port despite the pod reporting `2/2
Running`. PR #1323 explicitly left this open as a distinct, unfixed bug. It
was never logged into `docs/incident-log.md`.

## What was checked before logging it

Re-verified this is genuinely distinct from this repo's three prior
NetworkPolicy port/namespace-mismatch incidents (2026-08-04 harbor egress
allowlist, 2026-08-07 harbor ingress port, 2026-08-25 kargo egress
port/namespace — the last one already logged by an earlier cycle this run):
statically re-read both halves of the xDS NetworkPolicy pair
(`allow-envoy-proxy-xds-egress.yaml` / `allow-envoy-controller-xds-ingress.yaml`)
and confirmed they agree on port (TCP 18000) and selector
(`control-plane: envoy-gateway` / `app.kubernetes.io/component: proxy`) —
structurally correct, not a manifest bug. `allow-envoy-proxy-xds-egress.yaml`'s
own header comment already documents this exact failure shape as a known
"LATENT gap": the long-lived xDS stream survives until something restarts,
then doesn't reconnect on its own. This session cannot observe live pod/
stream state (ADR-0004) — logged what's known, not what's assumed.

## The fix

Added one row (2026-08-25, **P1**, matching this repo's existing "single
always-on component degraded / security-relevant gap" classification —
Envoy Gateway is the sole north-south ingress, ADR-0008) citing PR #1323,
the restart count, the specific gRPC error, and the static NetworkPolicy
re-check that rules out the prior bug class. Left explicitly **Unresolved**
— no live-cluster fix attempted or claimed. Added a matching bats assertion
(`tests/incident-log.bats`) so a future edit can't silently drop this row.

`make ci`: green (full local run including real `bats`, 2340+ tests, 0
failures).

## PR

https://github.com/tooming/k8s-anywhere/pull/1329
