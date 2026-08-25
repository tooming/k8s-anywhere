# docs: log the harbor NetworkPolicy port-mismatch incident (PR #1054)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's seventh cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes found nothing new this cycle
either. **No prerequisites — executor may pick up immediately.**

## The gap

Continuing this run's mining of issue #631/#633's comment history for real,
undocumented incidents (after the kro, argo-rollouts, and vault-unsealer
entries added in prior cycles): a 2026-08-07 live-cluster session found and
fixed a real, previously-undiscovered bug that had silently blocked *every*
cross-namespace request from Envoy Gateway to Harbor since the policy was
first written. `gitops/harbor/networkpolicy/allow-harbor-ingress.yaml`'s own
header comment records the full finding — the exact same shape of record
`docs/incident-log.md` exists to capture — but it was never added there.

## The incident

`allow-harbor-ingress.yaml` listed port **80** (Harbor's Service port)
instead of **8080** (the `harbor-nginx` pod's actual `containerPort`).
NetworkPolicy `ports:` match the destination *pod's* port, not the
Service's — a distinct failure mode from the already-logged
`envoy-gateway-system` egress-allowlist incidents (2026-08-04/2026-08-07),
which are about a missing namespace entry, not a port mismatch. This is why
every one of issue #631's earlier real, distinct fixes (Cilium drift, stale
Harbor creds, missing GitLab runner, Vault sealed, probe timeouts, disk
pressure) never actually got a signed image through — the ingress path
itself was silently broken the whole time.

## The fix

Added a new row (2026-08-07, **P1**) to `docs/incident-log.md`, positioned
chronologically right before the existing 2026-08-07 egress-allowlist row.
Cites PR #1054 (the fix) and the specific verification method used
(Envoy's `/clusters` admin endpoint showing `cx_connect_fail` against a
confirmed-healthy pod IP). Added a matching bats coverage test.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1316
