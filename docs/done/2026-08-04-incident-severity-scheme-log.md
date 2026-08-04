# Incident classification (severity) scheme + incident log

(CHARTER **Goals** §"operational-resilience discipline" — DORA's incident-management
pillar mapped onto concrete practice; planner-fallback gap analysis 2026-08-04,
reached via `executor.prompt.md` STEP 6b after all three standing "Now / next" items
were found gated on unconfirmed maintainer-confirmation issues #631/#633 with no
live-state-safe slice to split off. **No prerequisites — executor may pick up
immediately.**) Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s
Q6 ("Is there a documented incident classification (severity) scheme?") answered
"No... Gap: real" and Q7 noted the same absence; the file's closing summary named
this the one *structural* (non-cadence) DORA gap left — "neither [`make
dora-metrics`'s MTTR row nor its change-failure-rate row] is a substitute for a
severity scheme or a root-cause incident log for live-cluster events."
`docs/dora-resilience-mapping.md`'s Pillar 2 section cited only the CI-health MTTR
metric, nothing about classification or a log. Grepping ROADMAP.md and `docs/` for
"incident classification"/"incident log" turned up nothing already tracking this.
This was genuine, real gap-analysis output (Core Value/Goal not covered), not
manufactured filler — and unlike the three gated items ahead of it, it mutates no
live-synced cluster state at all (pure docs), so it carries zero blast radius risk.

Added `docs/incident-log.md`: a severity scheme (P0–P3) sized for this lab's actual
solo-operator, clusterless-by-default shape — explicitly naming "no paging, no
escalation path" as an intentional non-goal (mirroring Q7's own gap note) rather than
a silent absence; a "How to log a new incident" template row shape (mirrors the
existing `| Field | Content |` template already used in
`docs/dora-audit-readiness.md`'s own "Template for a new question"); and a backfilled
"Real incident history" table of the real, already-observed incidents narrated in
issue #631/#633's own comment history (verified directly against those comments, not
fabricated, ADR-0004): Cilium agents losing apiserver connectivity after a k3d node
IP reshuffle (fixed live via `make cilium-up`); the `artifactory` namespace's
default-deny NetworkPolicy missing an intra-namespace allow so `artifactory-oss`
could never reach its own bundled `postgresql` (fixed in PR #884); Harbor's
HTTPRoute unreachable because `allow-envoy-proxy-backend-egress` never allowlisted
the `harbor` backend namespace (fixed in PR #968); Harbor's Vault-held admin
credential never matching Harbor's real password (fixed live, not GitOps-managed, no
PR); and the still-open finding that no GitLab Runner has ever been registered
against this lab's GitLab instance, logged honestly as an unresolved row (no
fabricated resolution).

Updated `docs/dora-audit-readiness.md`'s Q6 answer from "No" to "Yes" (citing the new
doc); also updated Q8 ("Are incidents logged with root cause...") from "No dedicated
incident log exists" to "Yes" — found during implementation that the new log
naturally satisfies Q8 too (root cause + fix + follow-up columns), so leaving Q8's
stale "No" answer in place next to a file that now answers it would itself have been
doc drift. Left Q7's alerting/escalation gap language intact — this item adds
classification + logging, not automated paging. Updated the closing summary
paragraph to reflect both closures while keeping the honest residual gap (no
automated detection/alerting) explicit. Added a pointer sentence to
`docs/dora-resilience-mapping.md`'s Pillar 2 section and a one-line cross-reference
from `docs/DR.md`'s "Recovery cookbook" section. New `tests/incident-log.bats`:
severity scheme presence, non-goal framing, template presence, backfilled-incident
presence (grep for `#884`, `#968`, `Cilium`, `GitLab Runner`), ADR-0004
fabrication-guard, and that both `dora-audit-readiness.md`'s Q6 and Q8 blocks
reference the new file. `make ci` passed locally (lint/readme-check/lab-ui-check/
roadmap-check/markdown-links-check/drift checks green on this docs-only diff; the
usual cluster-tool checks skip in this clusterless sandbox and run for real in
GitHub Actions). Zero live-cluster blast radius — no `gitops/` files touched.

## PR

https://github.com/tooming/k8s-anywhere/pull/973
