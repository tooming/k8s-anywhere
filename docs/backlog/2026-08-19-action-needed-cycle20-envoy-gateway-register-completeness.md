# [Action needed] Now/next still gated; Envoy Gateway + register completeness confirmed safe (cycle 20)

**Date:** 2026-08-19
**Cycle:** 20th cycle this run

## What's blocked

Unchanged: the "Now / next" lane holds the same three items re-confirmed
every cycle this run — the two GitLab→Forgejo migration items (per their own
investigation notes) and the legacy capstone `Deployment` removal on issue
#633 — re-checked again, `updated_at` still 2026-08-17T18:50:01Z.

## What was tried this cycle

Three different angles, each a genuine attempt at fresh ground beyond
cycles 9–19's coverage:

1. **Direct Envoy Gateway GHSA-page audit** (`github.com/envoyproxy/gateway/
   security/advisories`) — this always-on-core ingress control plane hadn't
   had a *direct* advisory-page sweep recorded since 2026-07-18. Fetched all
   7 published advisories, including one **Critical** (GHSA-wcrf-9vrr-854f,
   CVSS 9.1, EnvoyExtensionPolicy Lua path-validation bypass → secret
   disclosure) and one **High** (GHSA-22xc-xg2r-9j7v, CVSS 7.4, unauthenticated
   xDS `Fetch` RPC in `GatewayNamespaceMode`). Checked each individually:
   **all 7 are patched at `v1.7.4`/`v1.8.1`** — this lab's pin
   (`gitops/platform/envoy-gateway.yaml`'s `targetRevision: v1.8.3`) is past
   every floor. Cross-checked against ADR-0008's own Re-evaluation log: the
   2026-07-18 entry ("Envoy Gateway CVE sweep kept, audit #515") already
   names these exact same 7 GHSAs by the same fix descriptions — this
   cycle's fetch independently reproduced, not discovered, that finding. No
   new ADR entry added (would be a pure duplicate of an existing one,
   against ADR-0004's spirit of grounding entries in real distinct
   findings). Also confirmed no `v1.8.x` patch newer than `v1.8.3` exists
   (`git ls-remote --tags`: `v1.8.3` is the newest `1.8.x` tag, next is the
   already-deliberately-deferred `v1.9.0` major).
2. **`docs/dependency-register.md` completeness cross-check** — prompted by
   `docs/dora-audit-readiness.md` Q14's own named gap ("the register has no
   mechanical drift guard yet — it's a manual snapshot"). Cross-referenced
   all 38 ADRs in `docs/decisions/` against the register's rows: 28 are
   cited (32 tools across 24 non-superseded ADRs, matching Q14's own
   count), 10 are not. All 10 are legitimately out of scope by design — 5
   are cross-cutting policy/principle ADRs with no single tool
   (ADR-0003/0004/0005/0025/0026), 2 are superseded-and-correctly-retired
   tool ADRs already represented under their superseding ADR's row
   (ADR-0010→ADR-0018 Valkey, ADR-0011→ADR-0024 Harbor), 2 are policy-only
   ADRs about an already-cited tool (ADR-0016/0017 — Cilium NetworkPolicy
   and PSS profile, Cilium itself cited under ADR-0014), and 1 is a
   version-pin policy for an already-cited tool (ADR-0030 — k3s itself
   cited under ADR-0027). **The register's coverage is complete and
   correct** — no missing row found. Did not attempt to build a mechanical
   completeness guard for this: doing so safely would need either a
   network-dependent live-reachability check in `make ci` (which
   `scripts/markdown-links-check.sh`'s own header comment already
   deliberately excludes as "a different, network-dependent problem", a
   design choice this repo has held since that script was written) or a
   hardcoded tool-vs-policy ADR allowlist (the same kind of drift-prone
   hardcoded list that caused cycles 17–18's bugs in the first place) —
   both worse than the manual-snapshot status quo Q14 already documents
   honestly.
3. **CHARTER Objective O7 spot-check** — confirmed `scripts/dora-metrics.sh`
   exists, is executable, and the `dora-metrics` Makefile target is wired
   (`make dora-metrics: ## Compute DORA metrics...`), matching O7's own
   "Measured by" bar exactly. Already met; no gap.

## Why this is the honest deliverable

A Critical-severity GHSA re-confirmed safe on this lab's most critical
always-on control plane, a full register-completeness audit confirming no
regression since Q14 was written, and an Objective spot-check — all came up
clean. Recording honestly per ROADMAP rule #9 and `executor.prompt.md` STEP
6b/STEP 8. Going straight back to STEP 1 for the next cycle.
