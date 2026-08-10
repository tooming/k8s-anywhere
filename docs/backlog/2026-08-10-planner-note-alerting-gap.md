# Planner note — 2026-08-10 (Grafana/Mimir alerting RFC gap)

**Reached via:** `executor.prompt.md` STEP 6b, PLANNER fallback, third cycle this run
(after `auto/external-secrets-chart-2-9-0` and `auto/pyroscope-chart-2-2-1`, both
executor-fallback currency bumps). The three standing Now/next items
(`auto/cosign-enforce-flip`, `auto/o4-ci-rejection-gate`,
`auto/capstone-deployment-removal`) remain gated on unconfirmed
maintainer-confirmation issues #631/#633/#1034 — re-checked, unchanged since
2026-08-07.

**Intake grooming:** `gh issue list` equivalent (GitHub MCP tools) still shows exactly
the three standing `[Action required]` confirmation issues, already correctly
labeled. Nothing to groom.

**Gap analysis — currency sweep (continued from this run's prior two cycles):**
extended the `git ls-remote --tags` sweep to every chart/image pin not yet re-checked
this run: cert-manager, keda, vault, ack-s3, kargo, envoy-gateway, node-exporter,
alloy, mimir, tempo, rabbitmq, valkey, k3s, gitlab-ce, gitlab-runner. All confirmed
current against their real upstream tag/release source — no further version gap
found. (Two earlier gaps this run, External Secrets Operator and Pyroscope, already
shipped as `auto/external-secrets-chart-2-9-0` / `auto/pyroscope-chart-2-2-1`.)

**Gap analysis — audit doc:** widened the lens per STEP 8's "different angle"
guidance to `docs/dora-audit-readiness.md`'s own self-flagged gaps. Q7 ("Is there a
defined detection → escalation → resolution path?") names a real, unaddressed gap:
"no alerting (Grafana has dashboards, not alert rules, as far as this repo's `gitops/`
shows)". A prior cycle (2026-08-07, cycle 7's own record) surveyed this same set of
gaps (Q7/Q13/Q15/Q16/Q17) and declined to promote any, judging them all
self-described as "minor"/"lowest priority" relative to that day's other work. Revisited
Q7 specifically this cycle: verified directly (ADR-0004) that Mimir's ruler mechanism
is already wired (`ruler_storage` on Garage bucket `mimir-ruler`, `rule_path:
/data/ruler` in `gitops/observability/mimir/configmap.yaml`) but genuinely empty — a
repo-wide grep for `PrometheusRule`/rule-group YAML under `gitops/` finds nothing.
This is a real, CHARTER-aligned Core Value gap (operational-resilience discipline),
not manufactured filler, and unlike the other four Q-gaps it has a concrete, buildable
shape once an architect makes three real design calls (which failure conditions,
which alerting mechanism — Mimir ruler vs. Grafana Unified Alerting, and whether any
notification receiver is warranted for a solo-operator lab with no existing pager/
Slack/email channel).

**Added as a new 🟡 item** in ROADMAP.md's "Cross-cutting hardening & quality"
section, per planner.prompt.md STEP 3 (planner tags gap-analysis findings 🟢/🟡
directly — the "don't append new 🟡 items" caution in that section is scoped to the
architect role writing there directly to avoid conflicting with the planner's own
edits; the planner itself is the actor curating that section). Named the specific
open questions and a recommended default (visual-only alerting, no external
notification receiver, given ADR-0025's free/OSS-tier constraint and no existing
channel to wire a receiver to) without pre-deciding them — that's the architect's
call, not the planner's.

**Why this run stops at PLANNER rather than falling through to ARCHITECT:** this is
a real planner deliverable per planner.prompt.md STEP 4 ("gap analysis... produced
ANY ROADMAP changes" → deliver as the plan PR) — the item is now visible and
RFC-ready. This run's *next* cycle, per STEP 8, will re-check the lane fresh and can
invoke ARCHITECT directly if this remains the topmost un-RFC'd 🟡 item found.

**No `[Action needed]` PR this cycle** — real backlog-grooming work was produced.
