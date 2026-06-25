# `docs/00-architecture.md` — current-state rewrite

`docs/00-architecture.md` — current-state rewrite (CHARTER **Core Values**
§"Docs & dashboards don't drift"; docs-only). The file is 70 lines and was written when
the platform had ~8 components; it now runs ~28 ArgoCD Applications across four
categories (always-on core, LGTMP observability, Tier 1 next-wave, on-demand heavy)
and the doc mentions none of the new components. Rewrite `docs/00-architecture.md` to
reflect the current platform state:
(a) **Updated tool table** — expand the "Who does what" table to cover the full
always-on stack: Cilium (CNI), External Secrets Operator, Garage (S3), s3manager,
RabbitMQ, Valkey, Alloy, Mimir, Loki, Tempo, Pyroscope, Grafana, kube-state-metrics,
node-exporter, moto, ACK S3, KRO, Kyverno, Argo Rollouts, Velero, Trivy Operator, and
the capstone pipeline (cosign → verifyImages → progressive canary). Describe each
tool's role in one line. Group rows by layer (matching the README table structure so
they stay in sync).
(b) **Updated learning path** — the current five-step path ends with "Tie it together"
via GitLab CI; expand to cover the full CHARTER Goals: supply-chain security
(cosign → Kyverno verifyImages), progressive delivery (Argo Rollouts canary on Mimir
SLOs), stateful backup/restore (Velero → `make dr-restore`), and continuous scanning
(Trivy Operator). The existing steps 0–5 can stay; add steps 6–9 or rewrite them.
(c) **Updated diagram** — either expand the ASCII diagram or replace it with a prose
description of the platform's current data-flow layers: bootstrap → GitOps → ingress
→ workloads → secrets → observability → security (admission + supply-chain) → backup.
No new CI gates; no new code. All assertions about what's deployed must reflect what's
actually in `gitops/` (ADR-0004 — no fabricated state). `make ci` must pass.
`docs/done/` entry required. (auto/architecture-doc-rewrite)

## PR

https://github.com/tooming/k8s-lab/pull/275
