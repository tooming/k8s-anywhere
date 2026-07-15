# ADR-0016 — formalize the observability namespace's intra-namespace carve-out

ROADMAP rule #9's coverage/hardening fallback lane, continuing the sweep from
#417/#419: cross-checked every `` `gitops/...yaml` `` file path referenced from
`docs/decisions/*.md` against the filesystem. Found `gitops/observability/networkpolicy/
allow-intra-namespace.yaml` (`NetworkPolicy allow-observability-intra-namespace`) grants a
namespace-wide `podSelector: {}` allow on both ingress and egress — a live deviation from
ADR-0016's binding text, which states under "Per-workload explicit-allow policies": *"No
catch-all 'allow same namespace' — every edge is explicit."* The `observability` namespace
was not listed in ADR-0016's "Carve-outs / special handling" table, so this was running as
an **undocumented** exception, not a sanctioned one — the manifest's own comment argues the
broad allow is intentional, but that argument was never brought back into the ADR.

Per CLAUDE.md's binding rule ("Never silently violate an ADR... requires you to STOP and
ask first"), this was surfaced to the maintainer before acting. Decision: **formalize the
existing behavior as a documented carve-out** (rather than splitting into granular
per-flow policies, which would need live-cluster verification this session doesn't have,
or leaving the gap unaddressed).

## Changes

- `docs/decisions/adr-0016-default-deny-networkpolicy.md`: added an `observability` row to
  the "Carve-outs / special handling" table, with the manifest's existing rationale (many
  legitimate intra-namespace LGTMP flows; every pod in the namespace is part of the same
  single-tenant pipeline, unlike namespaces mixing independent workloads) and an explicit
  flip condition (replace with per-flow policies if a future threat model requires
  intra-namespace segmentation within `observability`).
- `gitops/observability/networkpolicy/allow-intra-namespace.yaml`: updated the header
  comment to point at the new ADR-0016 carve-out row, so the manifest and the ADR each
  reference the other.

No manifest *behavior* changed — this is a documentation-only formalization of the
already-running policy. `make ci` passes (bats/lint locally; full suite in GitHub
Actions).

(auto/adr-0016-observability-carve-out)

## PR

<!-- filled in after opening the PR -->
