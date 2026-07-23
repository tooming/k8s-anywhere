# [Action needed] Now/next still gated post-Envoy-Gateway-fix; real cycle deliverables were PR #672/#673/#674, not idle

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, still zero comments.

## What this run actually delivered (three merged PRs, not idle)

This wasn't an idle run. Reaching STEP 6b's fallback chain with a starved
lane produced a full architect → planner → executor loop in three real,
merged PRs:

1. **PR #672** (architect fallback) — RFC #671: ADR-0008's 2026-07-18
   Re-evaluation log flip condition ("revisit when a new Envoy Gateway
   security bulletin names a version above `v1.8.2`") had fired. A prior
   cycle's PR #663 (2026-07-22T05:46 UTC) found `v1.8.3` existed as a GitHub
   tag but 404'd on Docker Hub, so it correctly held off. Re-verified live
   this cycle: the GitHub release (published 2026-07-22T18:59:00Z, TLS
   secret cert/key-mismatch validation fix) and the Docker Hub OCI artifact
   (`tag_status: active`, real digest, queried directly) both resolve now.
   Opened RFC #671, resolved the audit as **Convert**, queued the item via
   `docs/roadmap/incoming/`.
2. **PR #673** (planner fallback) — absorbed the queued item into
   ROADMAP.md's Now/next as the new topmost 🟢 entry.
3. **PR #674** (executor) — built it: bumped
   `gitops/platform/envoy-gateway.yaml`'s `targetRevision` `v1.8.2` →
   `v1.8.3`, added a new ADR-0008 Re-evaluation log entry, added
   `tests/envoy-gateway.bats` (no chart-pin recurrence guard existed for
   this component before), `docs/done/` record. Closed #671.

All three self-reviewed (gate integrity / ADR compliance / fabricated
content, plus the architect PR's four extra design-review checks) and
self-merged per WAYS-OF-WORKING.md §0.1.

## This cycle's sweep (post-fix), also empty

- **Planner:** no ungroomed issues beyond the three standing trackers;
  `docs/roadmap/incoming/` empty (the one file from this run's own architect
  PR was absorbed by this run's own planner PR, above).
- **Architect (fresh angle — full upstream sweep, not just flip-condition
  re-checks):** a parallel research pass read all 30 ADRs, cross-referenced
  `git log --since="7 days ago"` + every dated `docs/done/*.md` in the last
  week to build an exclusion list of what's already been audited/bumped
  (Grafana, Envoy Gateway, RabbitMQ, Istio/Kiali, Longhorn, Cilium, Inkless,
  Valkey, Kyverno, Argo Rollouts, Velero, Kargo, cert-manager, KEDA, k3s —
  14 of 30 ADRs touched this week alone), then live-verified everything
  else not yet covered (ArgoCD, Garage, Harbor, Trivy Operator) — all
  confirmed current, no action needed. Vault and TiDB have no dedicated ADR
  (referenced only as deployed workloads inside other ADRs), so there's
  nothing to "revisit" for them regardless.
- **Upgrade-drafter (fresh angle — every remaining chart pin not already
  ADR-gated or checked above):** live-verified ack-s3, harbor, kargo, keda,
  kro, tidb-operator, trivy-operator, vault (chart), alloy, grafana (chart
  packaging — separate axis from the already-current `13.0.3` app image
  tag), kube-state-metrics, node-exporter, pyroscope, istio — all at their
  latest stable release. One low-value finding declined: `grafana-12.8.0`
  chart exists (published 2026-07-21) but its only change is bumping the
  upstream chart repo's own `bats` test Docker image (their CI tooling, not
  anything this lab deploys or that reaches a running cluster) — zero
  functional delta for us, so bumping it would be exactly the manufactured
  churn ROADMAP rule #9 warns against, not real work. Declined; noted here
  instead of merged.
- **Doc-drift:** `make ci` clean (readme-check + lab-ui-check both pass with
  no drift warnings); no ArgoCD `Application` source path points at a
  missing `gitops/` directory (checked every `path: gitops/...` reference).
- **Triager:** all three open issues already fully labeled
  (`domain:*`/`readiness:*`/`priority:*`).
- **Janitor:** no TODO/FIXME markers in tracked source; every `scripts/*.sh`
  file already has at least one bats reference; no obvious duplication
  candidate found in a bounded pass.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked ADR
flip condition; (c) a new GitHub issue of any size.

This note is this cycle's honest record — the *previous* three cycles'
real deliverables were PR #672/#673/#674, not this note. The run continues
to the next cycle per `executor.prompt.md` STEP 8.
