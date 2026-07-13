# ADR-0028 — Oracle Cloud rejected as a cloud backend (supersedes ADR-0027)

**Decision.** Oracle Cloud Infrastructure is **rejected** as the lab's cloud backend.
[ADR-0027](adr-0027-first-cloud-backend-oracle-always-free-k3s.md) (Oracle Always Free
Ampere A1 + self-managed k3s) is superseded. All Oracle-specific code merged under
RFC #377 (`infra/modules/oracle-k3s-cluster/`, `infra/live/oracle/`,
`infra/tfstate-oracle/`, `scripts/tfstate-oracle-bootstrap.sh`,
`tests/oracle-cluster.bats`, the `tfstate-oracle-up`/`tfstate-oracle-down` Makefile
targets) is removed in this same change. `local/` (k3d) reverts to being the only
implemented backend.

**Why.** The maintainer directed "don't use Oracle" (2026-07-13), without stating a
reason. This ADR does not speculate on one — per ADR-0004, asserting a rationale that
wasn't actually given would be fabrication. What's certain: Oracle Cloud is off the
table as a candidate; the technical reasoning in ADR-0027 (the free-tier comparison
against AKS/GKE Autopilot) is not itself disputed, but is moot now that the provider
it was scoped to is rejected.

**What this does NOT do.** It does not change [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) —
the cloud-agnostic pluggable-backend architecture (the contract in
`infra/live/README.md`) stands; only the specific first-provider choice is reverted.
It does not select a replacement provider. Building a cloud backend remains 🟡
Yellow-tier work per [WAYS-OF-WORKING.md §2](../WAYS-OF-WORKING.md) — the next attempt
needs its own RFC, following RFC #377's process (compare candidates against
[ADR-0025](adr-0025-free-oss-tiers-only.md)'s zero-spend bar) but should ask the
maintainer up front whether they have a preferred or excluded provider before spending
effort on a full comparison and implementation, given this one was built end-to-end
before the rejection surfaced.

**Status.** Adopted 2026-07-13. Supersedes ADR-0027.
