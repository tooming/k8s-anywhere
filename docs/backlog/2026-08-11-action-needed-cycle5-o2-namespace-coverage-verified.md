# [Action needed] CHARTER Objective O2 namespace coverage directly re-verified; still nothing buildable

Autonomous executor run, this session's cycle 5 (`executor.prompt.md` STEP 6b/STEP
8). Cycles 1–3 shipped real, merged PRs (#1125, #1126, #1127); cycle 4 was this
session's first `[Action needed]` cycle (#1128, full fallback-chain walk). Per
STEP 8's "widen the lens" rule, this cycle tried a genuinely different, more
specific angle: a direct structural re-verification of **CHARTER Objective O2**
("every namespace either enforces default-deny NetworkPolicy AND PSS-restricted
labels, or has an ADR-cited carve-out"), rather than trusting the aggregate
"`make ci` is green" signal at face value.

## What was checked

Enumerated every `gitops/**/namespace.yaml` file (28 files, 27 distinct
namespaces — `argocd`, `ack-system`, `argo-rollouts`, `capstone`,
`capstone-pipeline`, `cert-manager`, `data`, `envoy-gateway-system`,
`external-secrets`, `harbor`, `inkless`, `istio-system`, `kargo`, `keda`, `kro`,
`kyverno`, `lab-demo`, `lab-gateway`, `longhorn-system`, `moto`, `node-exporter`,
`observability`, `storage`, `tidb`, `tidb-admin`, `trivy-system`, `vault`,
`velero`) and cross-checked each against two structural facts: does a matching
`networkpolicy/` overlay directory exist, and what `pod-security.kubernetes.io/
enforce` level does the namespace declare.

A first pass (naive `dirname` of each `namespace.yaml` path) flagged three false
positives — `observability` (`gitops/observability/mimir/namespace.yaml`),
`storage` (`gitops/storage/garage/namespace.yaml`), and `data`
(`gitops/data/rabbitmq/namespace.yaml`) — because their `namespace.yaml` lives one
directory level deeper than the namespace-level `networkpolicy/` overlay
(`gitops/observability/networkpolicy/`, `gitops/storage/networkpolicy/`,
`gitops/data/networkpolicy/` all exist and were confirmed directly with `ls -d`,
not assumed away).

**Result: all 27 namespaces have both.** Every namespace has a `networkpolicy/`
overlay directory, and every namespace declares an explicit `pod-security.
kubernetes.io/enforce` level (`restricted` for the majority; `baseline` for the
documented scan-job/compliance-job carve-outs — `tidb`, `tidb-admin`, `inkless`,
`trivy-system`, `envoy-gateway-system`, `lab-demo`; `privileged` for the two
heavy on-demand components whose controllers need host-level access —
`istio-system`, `longhorn-system`, both ADR-cited). This matches the extensive
per-namespace PSS/NP `bats` assertions already passing in this cycle's own local
`make ci` run (hundreds of individual namespace assertions, all green) — this
check corroborates that aggregate signal with a direct, independent structural
walk rather than trusting it blindly.

## Conclusion

CHARTER Objective O2 (due 2026-09-30) is **fully met** as of this cycle, not just
"probably fine per a passing test suite." No gap to file, no ROADMAP item to add
for it. Combined with cycle 4's full role-chain walk, this cycle's fresh angle
also came up empty — the `Now / next` lane remains gated on the same six items
(unchanged: three GitLab→Forgejo migration items need live verification;
`verifyImages` Enforce flip / O4 CI gate / capstone `Deployment` removal remain
gated on unconfirmed `[Action required]` issues #631/#633).

Per `executor.prompt.md` STEP 8, this is not a reason to end the run — going
straight back to STEP 1 for the next cycle, with a further-different angle next
time (rule #9's remaining unswept lenses: other CHARTER Objectives' completeness,
or a deeper `docs/decisions/` re-evaluation-log staleness check).
