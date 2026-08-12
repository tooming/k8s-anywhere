# [Action needed] Now/next fully gated; full STEP 6b fallback chain exhausted this cycle

**Date:** 2026-08-12
**Cycle:** 4th cycle this run (after PR #1131 — Loki/Tempo/Pyroscope dashboards, PR
#1132 — planner-fallback stateless-criticality-tiers item, PR #1133 — building that
item)

## What's blocked

The "Now / next" lane holds six unchecked items, all gated, unchanged from the start
of this cycle:

1. **Flip `Application` `repoURL`s to the Forgejo remote** — explicit live-cluster-only
   flip; this item's own text states a clusterless remote session must not attempt it.
2. **Rename `scripts/gitlab-*.sh` → `forgejo-*.sh`** — sequentially blocked on item 1.
3. **Decommission `gitlab/docker-compose.yml`** — sequentially blocked on items 1–2.
4. **`verifyImages` ClusterPolicy Audit → Enforce flip** — gated on standing issue
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (re-checked this cycle:
   still open, most recent comment 2026-08-11, does not confirm the gate).
5. **O4 CI gate — `verify-image-rejection` job** — sequentially blocked on item 4
   merging first.
6. **Remove legacy capstone `Deployment`** — gated on standing issue
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-checked this cycle:
   still open, most recent comment 2026-08-11, does not confirm the gate).

No live-state-safe slice was found to split off any of these (item 1 is itself
already the split-out gated slice from a prior rule-#9 split).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER**: no open issue is groomable intake (the only two open issues, #631 and
  #633, are the standing maintainer-confirmation trackers above — not user work
  requests). No un-RFC'd 🟡 item exists anywhere in ROADMAP.md (verified: zero `- [ ]
  🟡` lines in the file). A currency sweep across ten upstream charts/images (ArgoCD,
  Trivy Operator, Grafana, Loki/Tempo/Pyroscope, Kargo, RabbitMQ, Cilium,
  cert-manager, Velero, KEDA) found nothing stale. (This is the *second* planner pass
  this run — the first, earlier this cycle, found and delivered a real gap
  (stateless-criticality-tiering, PRs #1132/#1133); this pass is a fresh angle
  against the now-updated state and found nothing further.)
- **ARCHITECT**: no un-RFC'd 🟡 item to decide (same finding as above — the tag
  doesn't currently mark any backlog item).
- **DOC-DRIFT**: ran `make ci` and inspected every readme-check/lab-ui-check output
  line directly — zero drift signals (`✓ README in sync with Makefile targets`, `✓
  Lab UIs panel and README.md Endpoints table both match`, no broken pointers found).
- **JANITOR**: searched for TODO/FIXME/XXX markers in `scripts/`, `gitops/`, `infra/`
  — zero hits. Checked for scripts defining their own color/status helpers instead of
  sourcing `scripts/lib/colors.sh` — the one grep hit (`bluegreen-up.sh`/
  `bluegreen-down.sh`) was a false positive (`GREEN=` there is a k3d cluster-name
  variable for the blue-green DR concept, not a terminal color code). No genuine
  duplication, dead code, or missing recurrence guard found.

## What would unblock the standing gates

Both #631 and #633 need a live-cluster session with real host headroom to complete a
full pipeline run (build → cosign sign → push to Harbor → Kyverno admission →, for
#633, a Kargo promotion). Per #631's own comment history, every prior attempt this
week found and fixed a real, distinct root cause (NetworkPolicy port mismatch,
missing GitLab runner, Harbor S3-credential no-op field, Kyverno probe timeout,
node disk/CPU pressure) but has not yet completed one full pipeline run end-to-end —
the fixes are cumulative and real, the live verification itself keeps getting
preempted by host resource exhaustion.

This is a real, honest cycle outcome, not an idle declaration — per STEP 8, the run
continues past this point to the next cycle.
