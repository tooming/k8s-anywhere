# Janitor note — 2026-08-10 (ADR-0016 documented a decommissioned namespace)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, eleventh cycle this
run. Following the same successful pattern from cycle 10 (a subagent-delegated deep
gap-analysis sweep found a real ADR-0019 drift bug), this cycle delegated a second,
differently-scoped sweep targeting other ADRs' carve-out tables and CHARTER
Objective measurement claims — the same class of bug, in different files.

**What was found:** `docs/decisions/adr-0016-default-deny-networkpolicy.md` still
listed `artifactory` as a live, in-scope namespace in three places — the namespace
enumeration, the "On-demand namespaces" table row, and a dedicated carve-out table
row describing a specific `artifactory-oss-0` pod's `wait-for-db` NetworkPolicy
fix — but Artifactory was fully decommissioned 2026-07-29 (RFC #297 / ADR-0024,
`auto/harbor-artifactory-decommission`), the same date the carve-out row itself
cites as "found live." Verified directly: `find gitops -iname "*artifactory*"`
returns zero results; `gitops/platform/networkpolicy-appset.yaml`'s list-generator
has no `artifactory-networkpolicy` entry; `tests/no-artifactory.bats` is a standing
recurrence guard confirming none of it exists anymore. ADR-0017's equivalent
per-namespace table *was* updated with a dated closing entry at decommission time —
this ADR was the one left behind.

The same sweep also found `cert-manager` and `keda` — both real, live, auto-synced
namespaces with their own standalone `gitops/platform/{cert-manager,keda}-
networkpolicy.yaml` Applications (verified their `syncPolicy.automated` blocks are
real) — were never added to the enumeration in the first place, a separate grooming
gap from the Artifactory removal.

Fixed by:
1. Removing `artifactory` from the namespace enumeration and the "On-demand
   namespaces" table row.
2. Deleting the now-stale `artifactory` carve-out table row entirely (the
   namespace itself is gone, so no closing-entry row is needed there — unlike
   ADR-0019's `argocd` Kyverno carve-out, which kept the namespace and only
   dropped one policy exclusion).
3. Adding `cert-manager` and `keda` to the enumeration (now 28 namespaces).
4. Adding a new dated Re-evaluation log entry recording the full correction.

**No new mechanical guard added** — same reasoning as the ADR-0019 fix earlier
today: this is a one-off prose staleness with no existing drift-detection
mechanism, distinct from `tests/no-artifactory.bats` (which already guards the
`gitops/` manifests, not this ADR's prose) and `context.md`'s mechanically-enforced
version citations. A general "every ADR namespace enumeration must exactly match
`docs/dependency-tree.md`'s live namespace list" checker would be a much larger,
more invasive gate than this isolated two-item fix warrants — noted as a possible
future hardening idea, not built here.

**Why a second subagent-delegated sweep:** two prior shallow-check cycles (8, 9)
found nothing; cycle 10's subagent-delegated sweep proved the deeper, judgment-based
approach works. This cycle repeated that approach with a deliberately different
scope (other ADRs' carve-out tables, not ADR-0019 again) rather than assuming the
first hit was a one-off.
