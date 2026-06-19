# Architect run 2026-06-19 — PSS RFCs #229 + #230 (ESO + envoy-gateway-system)

**Run context.** Executor lane was blocked on two maintainer-gated items (ArgoCD PSS
Phase 2 awaiting in-cluster verification; verifyImages Enforce flip awaiting `.sig` tag
confirmation). Falling through the STEP 6b chain: PLANNER WIP slot taken by PR #227;
ARCHITECT slot free (no open `arch/*` PRs). This run files RFCs for two O2 PSS gaps
and updates ADR-0017 to record the architect's binding decisions.

## Gap analysis

CHARTER Objective O2 requires every namespace to either enforce default-deny
NetworkPolicy AND PSS labels, or have an ADR-cited carve-out in ADR-0017's
per-namespace profile table.

Audit of `gitops/` directories against ADR-0017's table revealed two always-on
namespaces absent from the table:

| Namespace | In gitops/platform? | In ADR-0017? |
|---|---|---|
| `external-secrets` | ✓ (wave 1, auto-synced) | ✗ — **gap** |
| `envoy-gateway-system` | ✓ (wave 0, auto-synced) | ✗ — **gap** |

## RFCs filed this run

| RFC | Namespace | Decision |
|-----|-----------|----------|
| [#229](https://github.com/tooming/k8s-lab/issues/229) | `external-secrets` | `restricted` — ESO 2.x runs as UID 65534, chart supports global securityContext overrides |
| [#230](https://github.com/tooming/k8s-lab/issues/230) | `envoy-gateway-system` | `baseline` — proxy data-plane pods use UID 0 in current chart defaults; two pod types share the namespace; `restricted` risks breaking north-south traffic |

## ADR-0017 update

Two rows added to the per-namespace profile table in this PR (`arch/pss-rfcs-eso-envoy`):

- `external-secrets → restricted` with RFC #229 citation
- `envoy-gateway-system → baseline` with RFC #230 citation and explicit flip condition

## What the planner should do next run

Groom RFC #229 into a single 🟢 executor item (`auto/pss-external-secrets`): namespace
manifest + extras Application + valuesObject patch + ADR-0017 row + bats. Small enough
for one PR.

Groom RFC #230 into a single 🟢 executor item (`auto/pss-envoy-gateway-system`):
namespace manifest + extras Application + ADR-0017 row + bats. Label-only (no workload
securityContext changes), well under the 400-line budget.

## No new ADR authored this run

Both RFCs extend the existing ADR-0017 per-namespace profile table rather than
introducing new technologies or architectural choices. The architect's decisions are
captured in the RFC issues and in the ADR-0017 table rows added in this PR.
