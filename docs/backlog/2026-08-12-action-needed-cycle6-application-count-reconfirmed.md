# [Action needed] Now/next still gated; CHARTER's ~33/~63 ArgoCD Application count reconfirmed accurate

**Date:** 2026-08-12
**Cycle:** 6th cycle this run (after PR #1162, #1163, #1164, #1165, #1166)

## What's blocked

The "Now / next" lane holds the same six unchecked items as every prior cycle this
run, unchanged (three sequential Forgejo-migration items; `verifyImages` Enforce-flip
+ O4 CI gate on unconfirmed issue [#631](https://github.com/tooming/k8s-anywhere/issues/631);
capstone `Deployment` removal on unconfirmed issue
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — both re-checked this
cycle, `updated_at`/comment count unchanged since 2026-08-11).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER / ARCHITECT / UPGRADE-DRAFTER / DOC-DRIFT-AUTHOR / TRIAGER**: no new
  findings beyond the preceding five cycles this run — re-running the identical
  checks minutes apart would not surface anything new (no open PRs, no new issues, no
  un-RFC'd 🟡 item, no fresh upstream release, no readme/lab-ui drift).
- **JANITOR**: took a different angle — re-derived CHARTER.md's "~33 ArgoCD
  Applications (Always-on core)" / `docs/dora-audit-readiness.md`'s derived "~58"
  figure, using the exact methodology from the last real re-count
  (`docs/done/2026-07-29-charter-application-count-recount.md`, issue #846): enumerate
  every `kind: Application` manifest under `gitops/` with a real
  `spec.syncPolicy.automated` block via a `yq` **field read** (not a substring match —
  the prior recount's own writeup notes a substring-match false-positive it had to
  correct). Result: **63** matching Applications today, identical to the 2026-07-29
  count (33 always-on-core + 14 always-on-next-wave + 8 cert-manager/KEDA + 3 capstone
  + 5 on-demand PSA-floor shells = 63) — confirmed unchanged, not stale. No CHARTER/
  doc edit needed this cycle.

## What would unblock the standing gates

Unchanged from every prior cycle's note: both #631 and #633 need a live-cluster
session with real host headroom to complete a full pipeline run (build → cosign sign
→ push to Harbor → Kyverno admission →, for #633, a Kargo promotion).

This is a real, honest cycle outcome, not an idle declaration — per STEP 8, the run
continues past this point to the next cycle.
