# Planner note (2026-06-30) — Harbor migration grooming (RFC #297 / ADR-0024)

Run trigger: the executor's nightly run found the 🟢 "Now / next" lane starved —
the only unchecked items there were both blocked on a human/cluster prerequisite:

- **verifyImages Audit→Enforce flip** (#214) — needs maintainer confirmation that a
  `.sig` tag exists in the registry + a live `curl`; unverifiable clusterless.
- **O4 CI gate `verify-image-rejection`** (#289) — gated on `auto/cosign-enforce-flip`
  merging first; the policy file still carries `validationFailureAction: Audit`.

Per `routines/executor.prompt.md` STEP 6b the run escalated to the **PLANNER** role to
refill the lane.

## What was groomed

[ADR-0024](../decisions/adr-0024-harbor-not-artifactory.md) (Harbor, **supersedes
ADR-0011**) is already **Adopted** on `main` (architect decision, merged via PR #302),
and ADR-0011 is marked Superseded. Issue **#297** is the RFC it came from; its standing
comment records that the planner should groom the remaining acceptance criteria into 🟢
executor items and that **#297 stays open until the migration lands and the footprint
gate is met**. Per WAYS-OF-WORKING.md §2 the architect's superseding ADR *is* the
approval — no human pre-approval gate — so the split items are 🟢, not 🟡.

The migration was split into six single-PR-sized items, added to *Now / next* in
dependency order:

1. **Harbor on-demand Application + namespace + Envoy route** (`auto/harbor-application`)
   — buildable now; mirrors the `artifactory` pair, minimal profile (Trivy/Notary off),
   Garage S3 storage, PSA `restricted` target.
2. **Harbor NetworkPolicy floor + appset entry** (`auto/harbor-networkpolicy`) — after #1.
3. **`make harbor-up` / `harbor-down` targets** (`auto/harbor-make-targets`) — after #1.
4. **ADR-0017 amendment — `harbor` PSA row** (`auto/harbor-pss-adr0017-row`) — after #1.
5. **Capstone pipeline re-wire — Artifactory → Harbor host** (`auto/harbor-capstone-rewire`)
   — gated on the maintainer-confirmed **12 GB footprint go/no-go gate** on #297.
6. **Decommission Artifactory manifests** (`auto/harbor-artifactory-decommission`) — gated
   on #5 + the footprint gate; **Closes #297** as the final slice.

Items 1–4 are buildable clusterless on the next executor run; items 5–6 carry a
maintainer-confirmation prerequisite (the live footprint measurement, which is an
operator/verifier — cluster-bound — step, not a clusterless executor step), mirroring the
existing enforce-flip maintainer-gate pattern.

No `docs/roadmap/incoming/` architect items were pending (only `README.md`). No other
open intake issues. No open PRs to de-dupe against.
