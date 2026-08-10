# Janitor note — 2026-08-10 (dependency-register's Envoy Gateway row missed a newer ADR-0008 entry)

**Reached via:** `executor.prompt.md` STEP 6b, JANITOR fallback, thirteenth cycle
this run. Fourth consecutive subagent-delegated deep gap-analysis sweep (following
cycles 10-12's real ADR-0019/ADR-0016/ADR-0021 findings), this time cross-checking
`docs/dependency-register.md`'s own "Last reviewed" claims against each cited ADR's
actual most recent Re-evaluation log entry.

**What was found:** `docs/dependency-register.md`'s Envoy Gateway row cited "Last
reviewed: 2026-07-23 (`v1.8.2` → `v1.8.3` bump)" — but
`docs/decisions/adr-0008-envoy-gateway-not-traefik.md`'s own Re-evaluation log has a
newer, dated entry: **2026-08-07 — Leader election disabled (chronic front-door 502
fix)**. Verified this is genuinely live, not just documentation talking to itself:
`gitops/platform/envoy-gateway.yaml` currently sets
`provider.kubernetes.leaderElection.disable: true` (with an explanatory comment
citing the same incident), and `git log` on the ADR file confirms the real commit
(`fix(envoy-gateway): disable leader election on single-replica control plane
(ADR-0008) (#1063)`, 2026-08-07). The register's own file-level "Keeping this in
sync" self-description was accurate for other rows re-dated the same day (ArgoCD,
Trivy Operator, Pyroscope) but the Envoy Gateway row itself was never bumped when
ADR-0008 picked up its later entry.

This is the register's own self-acknowledged risk realized: its "Real gap" section
already says "the register has no mechanical drift guard yet — it's a manual
snapshot that can go stale as future ADR bumps land without a matching register
update." This is exactly that.

Fixed by updating the Envoy Gateway row's "Last reviewed" cell to cite the
2026-08-07 leader-election fix, summarizing the trigger (17+ restarts/~2h during the
#631/#633 investigation) and the fix.

**No new mechanical guard added** — the register's own "no mechanical drift guard
yet" note already names this as a known, accepted limitation rather than a silent
gap; building a full ADR-log-vs-register-row consistency checker is a larger
project than this isolated one-row fix warrants (and the register's own docs
explicitly scope that as future architect-level work, not a mechanical drift-check
retrofit).

**Sweep scope this cycle (for the record):** every other dependency-register row's
cited ADR was cross-checked against its own most recent Re-evaluation log entry —
ADR-0001, ADR-0002/0007, ADR-0006, ADR-0009, ADR-0012, ADR-0013, ADR-0014, ADR-0015,
ADR-0018, ADR-0019–0022, ADR-0023/0024, ADR-0027, ADR-0028, ADR-0029, ADR-0031–0034
all matched. Only the Envoy Gateway row was stale.
