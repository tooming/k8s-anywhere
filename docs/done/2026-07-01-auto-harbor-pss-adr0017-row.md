# ADR-0017 amendment — `harbor` PSA row

Add a `harbor` row to the ADR-0017 §"Per-namespace profile" table recording that the
`harbor` namespace carries the `restricted` PSA profile. Harbor is Go-based; the
core/registry/jobservice components all run as non-root UID 10000 and the portal
uses nginx with a non-root UID in the 1.16.x chart — making `restricted` viable
without any securityContext carve-outs. The row cites ADR-0024 / RFC #297
(architect decision 2026-06-30) as the authoritative source.

The `harbor` namespace manifest (`gitops/harbor/namespace.yaml`) and the PSA label
assertions in `tests/harbor.bats` (added in `auto/harbor-application`) confirm the
`restricted` profile is the implemented and tested state.

## PR

PR #310
