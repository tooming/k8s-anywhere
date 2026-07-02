# ADR-0025 — Every dependency runs on a free / open-source tier

**Decision.** Every tool the lab depends on must run entirely on a **free / open-source
tier** — no paid licenses, no trial-gated features, no "contact sales" / enterprise
tiers, no usage-metered paid add-ons. Before proposing OR adopting any software, the
**specific capability the lab needs must be verified to exist in the free/OSS edition**.
An OSS edition merely *existing* is not sufficient — the *feature* has to be inside it.
If the capability lives only behind a paid tier, that tool is **disqualified**; choose a
fully-free alternative instead.

**Why.** The lab is a personal learning environment on a single 16 GB laptop; it must be
reproducible and runnable by anyone from `make up` with zero spend and zero license
procurement. A dependency that needs a paid tier to do its job is a dead end — it can't
be stood up in CI, can't be handed to another learner, and silently converts a
"self-hosted OSS" story into a vendor-billing one. Vetting the *feature* (not just the
edition) up front prevents the classic trap of adopting an "OSS" product and only later
discovering the one capability you needed is Pro-walled:

- **Artifactory OSS ≠ Pro** — replication and several repository types are gated behind
  paid Pro/Enterprise (called out in [ADR-0011](adr-0011-artifactory-not-nexus.md), a
  decisive factor in [ADR-0024](adr-0024-harbor-not-artifactory.md) choosing Harbor,
  whose single free edition has no such wall).
- The same test applies to every future tool: dashboards, SSO, HA, connectors, scanners
  — confirm the needed feature is in the free tier or pick something else.

**How this binds.** This is a foundational constraint that shapes **every** tooling ADR,
the same way [ADR-0003](adr-0003-decoupled-no-spof.md) (production-shaped) and
[ADR-0005](adr-0005-spof-recreate-over-ha.md) (recoverability over HA) do. It binds every
role — including the autonomous routines: a proposal, plan, or RFC that leans on a
paid-tier capability violates this ADR and must be reworked onto a free/OSS path (or, if
there is genuinely no free option, STOP and surface the trade-off per the CLAUDE.md
ADR-override rule). Note this constraint is distinct from routine **run-quota** budgeting
(WAYS-OF-WORKING.md §"cost"), which is about how often the cloud agents fire, not about
the licensing tier of the lab's software.

**Status.** Adopted. Consistent with and generalizing the free-tier reasoning already
embedded in ADR-0011 and ADR-0024; those remain the worked examples, this ADR states the
rule once so it is applied *before* a paid tool is ever proposed.
