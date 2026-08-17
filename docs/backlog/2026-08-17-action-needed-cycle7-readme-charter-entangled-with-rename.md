# [Action needed] Now/next still gated; README/CHARTER GitLab references entangled with the still-deferred rename item

**Date:** 2026-08-17
**Cycle:** 7th cycle this run (after PR #1203 — ACK bump, PR #1204 — kube-state-metrics
bump, PR #1206 — currency-sweep record, PR #1207 — industry digest 2026-W34, PR #1208
— GitLab→Forgejo rename item investigated/deferred, PR #1209 — dependency-register
GitLab→Forgejo row)

## What's blocked

The "Now / next" lane holds the same six items as every prior cycle this run, all
still gated — see PR #1206/#1208's own records for the full standing detail. No
change since the last check: issues [#631](https://github.com/tooming/k8s-anywhere/issues/631)
and [#633](https://github.com/tooming/k8s-anywhere/issues/633) are both unchanged
(`updated_at` identical to the last three cycles' checks).

## What was tried this cycle

Following up on PR #1209's dependency-register fix, checked whether the same
"GitLab → Forgejo" doc-drift class extends to `README.md` and `CHARTER.md`:

- **`README.md`** cites GitLab as the live git source in ~10 places (e.g. "GitLab
  holds the...", "main lives in the local GitLab (the GitOps source ArgoCD reads
  from)", "Push to GitLab for the running lab to pick up changes"). These are now
  inaccurate relative to the actual live cluster (Forgejo, per PR #1205) — **but
  they're still accurate relative to what `make up` and the current scripts
  actually produce.** PR #1208 (this run, cycle 5) already found and documented
  that `make up`'s bootstrap sequence still calls `gitlab-up`/`gitlab-configure`/
  `gitlab-tls-bootstrap`, not any Forgejo equivalent — the scripted, reproducible
  path is still GitLab-based even though one operator's live cluster was manually
  accelerated ahead of it. Rewriting README.md to describe a Forgejo-based flow
  `make up` doesn't actually produce would trade one inaccuracy for a different,
  arguably worse one (documenting a path that doesn't exist yet).
  `dependency-register.md`'s situation (PR #1209) was different: that file is
  explicitly a live-state register ("at a glance, which upstream projects the lab
  depends on"), not a reproducibility guide — a live-state correction was safe
  there in a way it isn't here.
- **`CHARTER.md`**'s "Target end-state" section names GitLab as part of the
  always-on core (line ~161) and the capstone inner loop (line ~180) — same
  entanglement: correcting it to "Forgejo" ahead of `make up` actually producing
  that state would make CHARTER.md internally inconsistent with README.md/the
  Makefile. CLAUDE.md also asks for extra caution on CHARTER.md edits (architect's
  lane, carried by an RFC/ADR, never a standalone drive-by edit) — ADR-0035
  already covers the decision, but a one-line sync here reads as exactly the kind
  of drive-by edit that guidance warns against doing casually.

**Conclusion:** both are real, verified gaps, but correctly left alone this cycle
— they're downstream of, not independent from, the still-deferred script/`make up`
rename item (PR #1208's finding). Fixing them now would desynchronize the docs
from each other rather than from reality. Recommend bundling the README.md/
CHARTER.md GitLab→Forgejo language sync into whichever future session completes
the `make up`/script rename item, so all of "what `make up` does," "what README
says it does," and "what CHARTER's target end-state says" move together.

PLANNER/ARCHITECT/TRIAGER re-checked this cycle: no ungroomed issues, no un-RFC'd
🟡 items, both open issues correctly labeled — unchanged from every prior cycle
this run.

This cycle's honest deliverable is this record. Going straight back to STEP 1 per
STEP 8 — this is not a stopping point.
