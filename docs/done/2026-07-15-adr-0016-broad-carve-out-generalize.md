# ADR-0016 — generalize the intra-namespace carve-out to all 7 instances

Follow-up to `auto/adr-0016-observability-carve-out` (same day). While formalizing the
`observability` namespace's undocumented `podSelector: {}` intra-namespace catch-out,
a broader sweep for the same `allow-*-intra-namespace.yaml` filename pattern across
`gitops/` found the identical pattern in **six more namespaces**: `argocd`, `harbor`,
`inkless`, `istio-system`, `longhorn-system`, `tidb`. Every one of the seven uses the
exact same shape (`podSelector: {}` on both `Ingress` and `Egress`), and every one's
own header comment already carried the same "single coherent multi-component stack"
rationale — this was never a one-off oversight, it's the repo's actual, consistent,
pre-existing convention for any namespace hosting one purpose-built multi-component
stack. Only `observability`'s instance had been reconciled with ADR-0016's carve-outs
table so far.

## Changes

- `docs/decisions/adr-0016-default-deny-networkpolicy.md`: added a second carve-outs
  row grouping `argocd`, `harbor`, `inkless`, `istio-system`, `longhorn-system`,
  `tidb`, with the same flip condition as the `observability` row, plus a **general
  principle** statement ("a namespace may use one broad intra-namespace allow instead
  of per-flow policies when every pod in it is part of the same single-tenant,
  purpose-built multi-component stack") so a *future* namespace following this same
  pattern doesn't create another undocumented gap — closing the recurrence loop per
  CLAUDE.md's bugfix-prevents-recurrence rule, generalized to a documentation gap.
- Updated all 6 manifests' header comments to point at the new ADR-0016 row (mirroring
  the `observability` fix from the prior PR).

No manifest *behavior* changed anywhere — documentation-only formalization of policy
that was already running. `make ci` passes (bats/lint locally; full suite in GitHub
Actions).

(auto/adr-0016-broad-carve-out-generalize)

## PR

<!-- filled in after opening the PR -->
