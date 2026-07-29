# CHARTER.md — remove stale "follow-up" framing for KEDA webhook TLS + ScaledObject demo

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b, this time via a "less obvious CHARTER Goal" lens
per STEP 8's guidance after the more direct fallback-chain passes this run had
already been exhausted.)

CHARTER.md's "Target end-state" §"Event-driven autoscaling" entry described two
pieces of KEDA follow-up work as still pending: "A follow-up wires its admission
webhook's TLS to cert-manager's `k8s-lab-ca` ... and adds a `ScaledObject` demo
scaling on the `data` namespace's RabbitMQ queue depth." Both are actually already
done — verified directly against the repo (ADR-0004), not assumed:

- `gitops/platform/keda.yaml` already carries the `certManager` block
  (`issuer.name: k8s-lab-ca`, `issuer.kind: ClusterIssuer`) wiring the admission
  webhook's TLS to cert-manager, per ROADMAP's checked-off
  `auto/keda-webhook-cert-manager-tls` item.
- `gitops/data/demo/keda-scaling/scaledobject.yaml` and
  `gitops/data/demo/keda-scaling/triggerauthentication.yaml` exist — a real
  `ScaledObject`/`TriggerAuthentication` pair scaling the `rabbitmq-load`
  Deployment on RabbitMQ queue depth, per ROADMAP's checked-off
  `auto/keda-scaledobject-demo` item.

This is the same drift class this run's earlier janitor pass
(`docs/done/2026-07-19-adr-followup-check.md`, PR #568) added a mechanical guard
for — an unchecked prose "follow-up" that went stale once the work actually
shipped — except this instance lives in CHARTER.md's prose, not an ADR's, so the
new `adr-followup-check` guard (scoped to `docs/decisions/`) doesn't cover it.
Fixed the prose to describe both as done, with a concrete file pointer
(`gitops/data/demo/keda-scaling/`) instead of a future promise.

Behavior-preserving: pure prose correction, no topology/decision change. `make ci`
passes.

## PR

[#571](https://github.com/tooming/k8s-anywhere/pull/571)
