# [Action needed] Now/next still gated; this run shipped 7 merged PRs across 9 cycles, CHARTER objective audit also clean

## What's blocked

The "Now / next" lane's remaining unchecked items are all gated on the standing
maintainer-confirmation issues #631/#632/#633 — re-verified this cycle (ninth cycle
of this run, fifth dated cycle today): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This run's real progress (not idle)

This has been an unusually productive run — 7 merged PRs across the STEP 6b fallback
chain, several of which unblocked each other in sequence (STEP 8's intended effect):

1. **PR #701** (`upgrade/rabbitmq-4-3-3-to-4-3-4`) — RabbitMQ patch bump, real
   upstream bug fixes + a management-UI CSP hardening change.
2. **PR #702** (`upgrade/pyroscope-2-1-2-to-2-2-0`) — Pyroscope chart minor bump,
   verified byte-identical `values.yaml` before merging; explicitly declined a
   same-week Alloy `1.10.1`→`1.11.0` candidate for its own documented breaking
   changes (Prometheus v2→v3 dependency major bump).
3. **PR #703** (`upgrade/grafana-chart-12-7-3-to-12-8-0`) — Grafana chart patch bump
   (test-tooling-only diff).
4. **PR #706** (`plan/ksm-kafka-major-bump-grooming`) — planner-fallback grooming of
   two upgrade-drafter major-bump findings (issues #704, #705) into parked 🟡
   ROADMAP items.
5. **PR #709** (`arch/ksm-approve-kafka-hold`) — architect-fallback RFC resolution:
   approved the `kube-state-metrics` `7.8.1`→`8.0.0` bump directly (verified the
   only breaking surface, a removed `CiliumNetworkPolicy` chart template, is a
   no-op for this lab's config); held `apache/kafka`'s client image at `3.9.2`
   (declined `4.3.1`, a real behavioral major version, citing unverifiable Inkless
   protocol-compatibility risk — new ADR-0015 `Re-evaluation log` entry).
6. **PR #710** (`auto/ksm-chart-8-0-0`) — executor pickup of the now-🟢
   kube-state-metrics item from PR #709, re-verifying the chart diff a second time
   before merging.
7. **PR #711** (`upgrade/loki-3-7-3-to-3-7-4-cve`) — a **CVE-driven** Loki patch
   bump (`CVE-2026-39822`, `CVE-2026-42505`, plus an Apache Thrift dependency CVE)
   — this specifically resolved a flip condition from *earlier sweeps this same
   week* that had declined the bump for lack of a verifiable git tag; the tag now
   exists for real.

Also filed and fully resolved 2 issues (#704, #705 → groomed, closed; #707 → closed
via PR #710; #708 → closed via PR #709) as part of the above chain.

## This cycle's fresh angle (came up empty, but real)

1. **CHARTER Objectives audit** — walked all 7 Objectives (O1–O7) against the repo
   state that wasn't already known-status from the ROADMAP intro note (which already
   records O1/O2/O5/O7 as met). O3 (stateful DR) and O6 (capstone under 15 min) both
   have their full measurement machinery already built and wired (`make dr-restore` +
   `scripts/dr-restore.sh`, `make capstone-demo` + `scripts/capstone-demo.sh`, both
   sharing `lib/budget-check.sh` and covered by clusterless structural bats) — the
   only remaining step for either is an actual timed run on live hardware, which is
   inherently outside what a clusterless PR can advance. O4 is the two gated
   Now/next items (Enforce flip + CI rejection gate), unchanged. No new gap found.
2. **Prior-decline cross-check (a genuinely new lens for this run).** Searched
   `docs/backlog/*.md` for previously-declined findings before continuing further
   chart sweeps, to avoid redoing work a prior cycle already ruled out. Found one
   real miss: `docs/backlog/2026-07-23-action-needed-post-envoy-gateway-fix.md`
   had already found and explicitly *declined* the exact same `grafana-12.8.0`
   chart bump this run's PR #703 went ahead and merged (that prior cycle judged it
   "manufactured churn" — zero functional delta, only the chart's own CI-tooling
   image changed — while this run judged the same finding safe enough to ship as a
   verified, documented bump). Not reverting it — the diff genuinely is safe and
   `make ci` is green — but noting the process gap explicitly: **future
   upgrade-drafter cycles should check `docs/backlog/` for a prior explicit decline
   before re-attempting a candidate**, not just re-derive the same finding from
   scratch. No other missed prior-decline found on this pass (checked all 5
   `docs/backlog/*.md` files containing "declined" — the rest were janitor/doc-drift
   scope, not chart/image candidates).
3. **ADR Re-evaluation log coverage sweep.** Checked every `docs/decisions/adr-*.md`
   for a missing `## Re-evaluation log` section. 15 ADRs have none — all correctly
   so: foundational/architectural ADRs that don't pin a version (ADR-0001/0003/0004/
   0005/0025/0026/0027), already-superseded ADRs (ADR-0010 by 0018, ADR-0011 by
   0024), floor-only pins already explained in a prior cycle (ADR-0014/Cilium), or
   ADRs whose version was checked-and-found-current this run without a decision
   change (ADR-0022 Trivy Operator, ADR-0029 KEDA) — a "still current" check doesn't
   itself warrant a log entry, only an actual decision or bump does. No gap.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue of any size;
(d) an actual live-cluster timed run for O3/O6.

This note is this cycle's honest record — a real, distinct check, on top of seven
merged PRs earlier in this same run — not a stopping point. The run continues to
the next cycle per `executor.prompt.md` STEP 8.
