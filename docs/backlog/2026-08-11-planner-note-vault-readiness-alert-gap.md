# Planner note — 2026-08-11 (Vault pod-readiness alert rule gap)

**Reached via:** `executor.prompt.md` STEP 6b, PLANNER fallback role
(`routines/planner.prompt.md`), first cycle this run. Fresh session start: local
`main` had drifted from `origin/main` (stale checkout from a prior container),
reset to `origin/main` (`9400f7b`) before anything else. STEP 1b: `gh`/`stale-prs-check`
unavailable in this environment (no `gh` CLI) — used the GitHub MCP tools directly
instead; `list_pull_requests --state open` returned zero open PRs, so there was
nothing stale to finish. STEP 2: zero open PRs confirmed no in-flight duplicate.

**STEP 3 — Now/next re-checked, still fully gated.** All three remaining GitLab→
Forgejo migration items (repoURL flip, script rename, GitLab decommission) are
sequentially gated on a live-cluster session pushing real content and verifying a
real ArgoCD sync — explicitly not attemptable from this clusterless session. The
other three unchecked items anywhere in `ROADMAP.md` (`verifyImages` Enforce flip,
O4 CI rejection gate, capstone Deployment removal) are gated on the standing
`[Action required]` issues **#631**/**#633** — re-checked both issues' full comment
history directly (not assumed): most recent comments on both are dated 2026-08-07,
still explicitly "not closing — still haven't observed" a signed image / a completed
Kargo promotion. No new comment since. Unchanged from every `[Action needed]` cycle
recorded in `docs/backlog/2026-08-11-action-needed-cycle*.md` from earlier today.

**Intake grooming:** `list_issues --state OPEN` shows exactly the same two standing
confirmation issues (#631, #633), already correctly labeled — nothing to groom.
`docs/roadmap/incoming/` holds only its `README.md` — no pending architect items.

**Gap analysis — fresh angle, not a repeat of today's earlier cycles.** Rather than
re-running the currency sweep / janitor sweep / dependency-register cross-check
already exhaustively covered by today's cycles 2–4
(`docs/backlog/2026-08-11-action-needed-cycle{2,3,4}-*.md`), re-read
`docs/dora-audit-readiness.md` end to end for a gap not yet promoted. Q7's own gap
line names one directly: "Vault sealed has no metric to alert on at all, since
Vault isn't currently scraped by Alloy... A future item could add a Vault-health
scrape job + alert rule if that gap is worth closing." Verified directly (ADR-0004):
no `prometheus.scrape "vault"` block exists in `observability-alloy.yaml` (25 named
scrape jobs, none for Vault), and RFC #1084's four existing alert rules don't cover
Vault (three of the four use metric families — ArgoCD app info, PVC phase — that
can't match Vault at all; the fourth, `DeploymentReplicasUnavailable`, structurally
cannot match Vault's `StatefulSet`). This isn't speculative risk: the
`vault-unsealer` Deployment's own header comment documents a real 2026-07-29
incident where Vault stayed sealed for 4+ days after an outage, "silently breaking
every ExternalSecret refresh cluster-wide... but nothing surfaced that anywhere
visible" — precisely the detection gap this closes.

**Added as a 🟢 item directly in "Now / next"**, not a 🟡 needing a new architect RFC
— it's a mechanical extension of RFC #1084's already-decided pattern (Grafana
Unified Alerting, threshold-over-instant-Mimir-query shape, visual-only, no
notification receiver) using a metric (`kube_pod_status_ready`) already scraped by
the existing `ksm` job, so no new scrape target or architectural call is needed.
Full implementation detail (exact `uid`/`title`/`expr`/`for`, the `pod=~"vault-
[0-9]+"` regex scoping rationale to exclude the separate `vault-unsealer` pod, and
the exact `tests/observability-alerting.bats` assertions to add/bump) is in the
ROADMAP item itself so the executor's next cycle can build it without re-deriving
any of this research.

**Why this run stops at PLANNER rather than falling through further:** a 🟢 item is
now sitting near the top of *Now / next*, ready for this run's own next cycle
(STEP 8) to build and merge without waiting for a future run — this is a real
planner deliverable per `planner.prompt.md` STEP 4.

**No `[Action needed]` PR this cycle** — real backlog-grooming work was produced.
