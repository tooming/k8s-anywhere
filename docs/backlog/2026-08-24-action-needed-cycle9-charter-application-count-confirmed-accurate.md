# [Action needed] Now/next still gated; CHARTER Application-count re-derivation confirms no drift (cycle 9)

Autonomous scheduled run — the executor's honest STEP 6b fallback record for
this cycle, `executor.prompt.md` STEP 6b, ninth cycle of this run.

## Now / next status

Unchanged from every earlier cycle this run: all three unchecked ROADMAP
items remain gated (see cycle 8's record for the last full re-check; issue
#633 unchanged).

## Resolving cycle 8's deliberately-scoped-out finding

Cycle 8 investigated CHARTER.md's "~33 ArgoCD Applications" (Always-on core)
figure but deliberately declined to force a fix, flagging that its
methodology "hand-groups multiple `Application` YAMLs into one conceptual
component" and needed the full categorization work redone properly rather
than guessed at. This cycle did that work.

**Method** (matching issue #846 / PR #849's own original methodology
exactly, not a new approach): downloaded a real `mikefarah/yq` binary
(v4.53.6 — the repo's own `yq` on `PATH` is a different variant per `make
ci`'s own "yq on PATH is not mikefarah/yq" warning, and PR #849's own
`docs/done/` record explicitly notes a text/substring match here produces
false positives). Enumerated every `kind: Application` manifest under
`gitops/` whose `.spec.syncPolicy.automated` field (a real field read via
`yq`, not a text grep) is non-null — **63** matched, identical to PR #849's
original count. Categorized all 63 against CHARTER's own five named buckets,
the same five PR #849 used:

| Bucket | July 2026-07-29 count | Now (2026-08-24) count |
|---|---|---|
| Always-on core | 33 | **33** |
| Always-on next wave (Kyverno/Rollouts/Velero/Trivy) | 14 | **14** |
| cert-manager + KEDA | 8 | **8** |
| Capstone | 3 | **3** |
| PSA-floor shells for on-demand heavy components | 5 | **5** |
| **Total** | 63 | **63** |

Every bucket's own membership list was checked name-by-name, not just its
count, against PR #849's original enumeration — one real, non-count-changing
churn found: `artifactory-extras` (present in July, part of the
now-decommissioned Artifactory→Harbor migration) is gone, and
`tidb-admin-extras` (not present in July's bucket-5 list) has since joined
the same "PSA-floor shell for an on-demand heavy component" bucket —
membership changed, the bucket's total (5) and the grand total (63) did not.
The Always-on-core bucket's own 33 members are byte-identical to PR #849's
original enumeration; the GitLab→Forgejo migration didn't touch this count
at all, since GitLab (like Forgejo) was always host-level Docker Compose,
never its own ArgoCD `Application`.

**Conclusion: CHARTER.md's "~33 ArgoCD Applications" and
`docs/dora-audit-readiness.md`'s derived "~58 Applications" figures are both
still accurate. No edit needed.**

## What this closes

This is the third distinct family of hand-maintained-doc-arithmetic checks
this run (after `dependency-register.md`'s Scope note in cycle 7, and the
count sweep in cycle 8) — but unlike those two, this one was a real
*verification*, not a fix: the figure cycle 8 flagged as unconfirmed is now
confirmed correct, closing that open thread rather than leaving it dangling.

**`make ci`:** green (unchanged; no repo content changed this cycle).

Going straight back to STEP 1 per STEP 8 — this is not a stopping point.
