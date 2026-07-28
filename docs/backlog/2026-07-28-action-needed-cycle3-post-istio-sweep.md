# [Action needed] Now/next still gated; upgrade-drafter + janitor fallbacks also clean this cycle

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on the standing
maintainer-confirmation issues #631, #632, #633 — re-verified this cycle: all three still
open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles this run)

- PR #823 (`plan/istio-observability-gap`) — planner gap-analysis fallback found and
  ROADMAP'd a real CHARTER Objective O5 gap: `istio-system-extras` (auto-synced under
  `gitops/bootstrap/root-app.yaml`, same ALWAYS-ON PSA-floor pattern as
  `kargo-extras`/`longhorn-extras`) had no Grafana dashboard and no Alloy scrape wiring —
  the only such Application without one.
- PR #824 (`auto/istio-observability-dashboard`) — built that item: new
  `prometheus.scrape "istiod"` block in `observability-alloy.yaml`, new
  `grafana/dashboards/lab-istio.json`, new `tests/istio-observability.bats`,
  `docs/dependency-tree.md` update. Both merged, `make ci` green throughout.

## This cycle's fresh angle

Per STEP 8's "widen it, don't repeat the identical search" guidance, tried two fallback
roles further down STEP 6b's chain that were genuinely untried by this run (planner's gap
analysis was already exhausted producing the istio item above):

1. **Upgrade-drafter fallback** — walked `gitops/**/*.yaml` for chart/image pins not
   already named in the extensive 2026-07-26/27/28 CVE-and-currency sweep notes (`docs/
   backlog/2026-07-26-*.md`, `2026-07-27-*.md`, and today's own
   `2026-07-28-action-needed-argocd-chart-major-line-vault-recheck.md`, which already
   shipped PRs #769/#771/#775/#777/#779/#780/#781 earlier today). Verified via
   `git ls-remote`/Docker Hub tags API: Kiali chart (`2.29.0`) is the current tag;
   `motoserver/moto` (`5.2.2`), `oliver006/redis_exporter` (`v1.88.0-alpine`),
   `curlimages/curl` (`8.21.0`), `danielqsj/kafka-exporter` (`v1.9.0`),
   `jaegertracing/example-hotrod` (`2.20.0`) are all the exact latest published tag.
   Artifactory has newer upstream releases but is out of scope to bump — ADR-0024 orders
   it decommissioned pending the same #631/#632/#633 gate, so bumping it now would be
   pure churn on a component slated for deletion. Valkey has a real `8.1.9-alpine` minor
   available but ADR-0018's own Re-evaluation log deliberately holds the pin at `8.0.x`
   absent a CVE on that line (flip condition not met) — a binding version-pinning ADR,
   hard-skip per upgrade-drafter's own rules. **No genuine unbumped, non-major,
   ADR-unpinned source found.**
2. **Janitor fallback** — read `tests/drift-detectors.bats` (22 guards) and all 23
   `scripts/*-check.sh` files; cross-checked against the already-exhaustive
   `docs/backlog/2026-07-28-action-needed-janitor-monolith-recurrence-check.md`
   (commit-touch-count monolith analysis) and
   `2026-07-26-action-needed-cycle6-janitor-duplication-check.md` (NetworkPolicy
   hash-dedup analysis). Independently re-grepped for TODO/FIXME across
   `.sh`/`.yaml`/`.tf`/`.hcl`/`.md` (excluding `docs/backlog`/`docs/done`): only the same
   3 already-tracked, non-orphaned TODOs turned up (`gitops/kyverno/policies/
   disallow-latest-tag.yaml`, `ROADMAP.md:3011`, `infra/modules/argocd/values.yaml:15`).
   `scripts/adr-chart-version-sync-check.sh` vs. `adr-image-pin-sync-check.sh` look
   superficially similar but guard genuinely distinct pin shapes (chart `targetRevision`
   vs. plain image tag) — not real duplication. **No new footgun, duplication, or dead
   matter found.**

Doc-drift and issue-triage were not re-run as separate fallback passes this cycle: `make
ci`'s `readme-check`/`lab-ui-check`/markdown-link checks all passed clean earlier this
cycle (verified directly, not assumed), and `gh issue list --state open` returns exactly
the three standing `[Action required]` issues above, each already correctly labeled
(`priority:p1`, a `domain:*` label, `readiness:green`) — nothing untriaged exists to route.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream CVE/release
firing a tracked ADR flip condition (Valkey `8.1.x`/`9.x` line, or any other pinned
component); (c) a new GitHub issue of any size to groom.

This note is this cycle's honest record — it follows a real, merged deliverable (PRs
#823/#824) earlier this run, not a substitute for one. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
