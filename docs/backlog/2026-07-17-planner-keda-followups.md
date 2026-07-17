# Planner run — 2026-07-17

## Trigger

The executor's own "Now / next" lane was fully gated this run: all four remaining
unchecked ROADMAP items (`auto/cosign-enforce-flip`, `auto/o4-ci-rejection-gate`,
`auto/harbor-capstone-rewire`, `auto/harbor-artifactory-decommission`) carry
maintainer-confirmation or live-cluster-verification prerequisites that cannot be
checked from a clusterless remote session, and the one remaining 🟡 item (vault PSA
audit) is explicitly marked "no RFC or 🟢 executor item is needed now — the executor
skips this item." No open GitHub issues, no pending `docs/roadmap/incoming/` architect
items. Falling back to the planner role per `executor.prompt.md` STEP 6b.

## Gap analysis

Compared CHARTER.md's "Target end-state" section against the actual `gitops/keda/`
tree. CHARTER's own KEDA entry and ADR-0029 §"Scope & exceptions" both explicitly name
two owed follow-ups to the already-merged KEDA engine (`auto/keda-engine`,
`docs/done/2026-07-16-keda-engine.md`):

1. Wiring the admission webhook's TLS to cert-manager's `k8s-lab-ca` `ClusterIssuer`
   instead of the chart's self-signed default.
2. A real `ScaledObject` demo scaling `rabbitmq-load` on the `data` namespace's RabbitMQ
   queue depth — the actual pedagogical payoff of the whole ADR.

Neither had ever been turned into a ROADMAP backlog item — verified via
`grep -rn "ScaledObject\|TriggerAuthentication\|certManager.*enabled" gitops/ tests/`,
which found zero hits outside the ADR's own prose and the `lab-keda.json` dashboard's
"no data yet" panel note. ADR-0029 already contains the full binding spec for both
(exact chart `valuesObject` fields, the wave-reordering fix required for item 1, and the
scope/NetworkPolicy shape for item 2), so both are groomed straight to 🟢 — no new
architect RFC needed, matching the precedent WAYS-OF-WORKING.md §2 sets for
RFC-pre-approved Yellow work.

## Items added to ROADMAP.md ("Now / next")

- **KEDA admission webhook TLS — wire to cert-manager's `k8s-lab-ca`**
  (`auto/keda-webhook-cert-manager-tls`) — patches `gitops/platform/keda.yaml`'s
  `valuesObject` with the `certificates.certManager` block and moves the three KEDA
  Applications from their current waves (0/1/4) to wave 6, alongside
  `lab-gateway-certificate`, to avoid the circular sync-wave deadlock ADR-0029 already
  identified.
- **KEDA `ScaledObject` demo — scale `rabbitmq-load` on RabbitMQ queue depth**
  (`auto/keda-scaledobject-demo`) — adds the `TriggerAuthentication` + `ScaledObject`
  pair in the `data` namespace, plus the NetworkPolicy egress/ingress additions needed
  for the KEDA operator pod (namespace `keda`) to poll RabbitMQ's management API
  cross-namespace. Corrected one inaccuracy while grooming: ADR-0029's text refers to
  "the existing `rabbitmq-creds` ExternalSecret," but the actual manifest is
  `gitops/data/demo/externalsecret.yaml`, Secret name `data-demo-creds` — the ROADMAP
  item cites the real name.

Both items are independent of each other and of the four still-gated items above them
in the lane, so either can be picked up next run regardless of which of the two gated
items eventually unblocks.

## Not groomed / no action

- No open GitHub issues to groom (intake queue empty).
- No pending `docs/roadmap/incoming/` architect items to absorb.
- The vault PSA-restricted 🟡 reminder item is left as-is per its own explicit
  "executor skips this item" note — it is not a buildable gap, just a standing reminder
  until the Vault chart changes upstream.
