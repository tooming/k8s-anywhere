# KEDA `ScaledObject` demo — scale `rabbitmq-load` on RabbitMQ queue depth

Second and final of ADR-0029's two explicit follow-ups to the already-merged KEDA
engine — the actual pedagogical payoff: scaling *demonstrated*, not just installed.
The first follow-up (webhook TLS via cert-manager) shipped in
`docs/done/2026-07-17-keda-webhook-cert-manager-tls.md`.

## What shipped

**`gitops/data/demo/keda-scaling/triggerauthentication.yaml`** — a `TriggerAuthentication`
named `rabbitmq-trigger-auth` reading `username`/`password` from the existing
`data-demo-creds` Secret (already rendered from Vault `rabbitmq/default`) — no new
credential seam.

**`gitops/data/demo/keda-scaling/scaledobject.yaml`** — a `ScaledObject` named
`rabbitmq-load-scaler` targeting the `rabbitmq-load` Deployment, `minReplicaCount: 1`,
`maxReplicaCount: 5`, `rabbitmq` trigger on `queueName: demo` via the management HTTP
API (`protocol: http`, host `http://rabbitmq.data.svc.cluster.local:15672`),
`queueLength: "1"`. Field names verified directly against the pinned KEDA v2.18.0
scaler source (sparse-cloned `kedacore/keda` at tag `v2.18.0`,
`pkg/scalers/rabbitmq_scaler.go`): the `host`/`queueName`/`queueLength`/`protocol`
trigger-metadata keys and the `TriggerAuthentication`'s `secretTargetRef[].parameter`
names (`username`/`password`) all confirmed against the actual struct tags, not
guessed from docs.

## A real finding: the original rabbitmq-load loop could never be observed scaling

Before writing the ScaledObject, traced through `rabbitmq-load.yaml`'s existing script:
publish 1 message, then *immediately* drain up to 10 in the same loop iteration, sleep
5s, repeat. That leaves the queue non-empty for only a network round-trip — far too
brief for KEDA's default 30s `pollingInterval` to ever reliably observe. Shipping the
`ScaledObject` against that traffic pattern would have been a demo that could
*structurally never* produce a scale event, which is arguably worse than "no data yet"
(ADR-0004: a demo that can never be observed is functionally the same as a fabricated
one). Fixed by changing `rabbitmq-load.yaml`'s script to a burst/drain cycle — publish
5 messages back-to-back, hold 40s (longer than the 30s default `pollingInterval`,
guaranteeing at least one poll lands inside the window), drain, hold empty 20s, repeat.
This still keeps the "Lab — RabbitMQ" dashboard's publish/consume-rate panels showing
real, non-zero movement (ADR-0004) — just in bursts instead of a flat trickle — while
giving the new `ScaledObject` a real, sustained ~5-message backlog to react to.

## Wave-ordering: a separate Application, not folded into data-demo

`data-demo` (the existing Application carrying `rabbitmq-load`/`valkey-load`) syncs at
wave 4 — but `ScaledObject`/`TriggerAuthentication` are KEDA CRD kinds, and `keda`'s
CRDs only exist once it syncs at wave 6 (moved there by the prior webhook-TLS PR).
Applying a CR before its CRD exists is a hard ArgoCD sync error, not a soft
"not found" — putting these two manifests inside `data-demo`'s wave-4 directory would
have deadlocked the bootstrap exactly the way ADR-0029's own wave-ordering finding
already described for `keda` itself. Fixed by creating a **separate** directory
(`gitops/data/demo/keda-scaling/`) and a **separate** auto-synced Application
(`gitops/platform/data-demo-keda-scaling.yaml`, wave 7 — after `keda`'s wave 6).
`data-demo`'s own Application/wave is untouched.

## NetworkPolicy

The KEDA operator pod (namespace `keda`) is what polls RabbitMQ's management API, not
`rabbitmq-load` itself. Added `gitops/keda/networkpolicy/allow-keda-egress-rabbitmq.yaml`
(egress TCP 15672 to the `data` namespace) and wired it into
`gitops/keda/networkpolicy/kustomization.yaml`. On the `data` side, confirmed the
existing `allow-rabbitmq-ingress.yaml`'s `from: - podSelector: {}` peer (no
`namespaceSelector`) only matches pods in the *same* namespace per NetworkPolicy
semantics — it did **not** already cover the `keda` namespace. Added a second,
narrowly-scoped ingress rule (TCP 15672 only, from `keda`) rather than widening the
existing AMQP/metrics block, so `keda` gets no access to ports it doesn't need.

## Bats coverage

New `tests/keda-scaledobject.bats`: `TriggerAuthentication`/`ScaledObject` shape and
field values, the `data-demo-keda-scaling` Application (path, namespace, auto-sync,
wave 7) and a guard that the CRs are *not* sourced by the wave-4 `data-demo`
Application, both NetworkPolicy allow files, and the `rabbitmq-load.yaml` burst/hold
timing. Updated `tests/keda.bats`'s prior "no ScaledObject/ScaledJob exists yet"
recurrence guard to instead assert the *only* ScaledObject/ScaledJob CRs are this
demo's, at the expected path.

## Docs

`docs/dependency-tree.md`: new wave-7 table row (`data-demo-keda-scaling`); updated the
KEDA prose paragraph to describe the now-built demo instead of the deferred follow-up;
updated the `data-demo` prose to describe the burst/drain timing; updated the "data
namespace network policy" prose to mention the new `keda`-scoped ingress allow.

## Verification

`make ci` green locally (lint/readme-check/lab-ui-check/roadmap-check pass); full
`bash scripts/test.sh` run locally with `bats` installed for this session — all new and
updated tests pass; the handful of pre-existing local-only failures (missing `helm`
binary, network-dependent checks) are identical on an untouched clone of `main`, not
introduced by this change. KEDA scaler field names and RabbitMQ Service/port verified
directly against the pinned chart/source, not assumed.

## PR

https://github.com/tooming/k8s-anywhere/pull/459
