# [Action needed] Now/next still gated; stale-pending-condition sweep clean, 10 PRs landed this run

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
recent cycle has found gated, re-verified fresh this cycle:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633).

Both issues' comment threads re-read fresh: still open, no new comment since
2026-08-04. Open PR [#980](https://github.com/tooming/k8s-anywhere/pull/980)
(human-authored, still open) is the maintainer's own live in-progress work
toward unblocking both.

## This cycle's fresh angle

The prior cycle (`2026-08-05-adr-0030-index-fix`, PR #1002) found a real,
resolved-but-unnoticed TODO in `infra/modules/argocd/values.yaml` by
recognizing the pattern "a comment says 'once upstream X ships Y, drop this
override' and this run just made upstream X ship Y." This cycle generalized
that pattern: swept the whole repo (`grep -rln` across `gitops/`, `infra/`,
`docs/decisions/`) for any other "no stable release exists yet" /
"not yet stable" / "doesn't exist yet" style pending-condition comment that
might now be resolvable. Found only the one occurrence already fixed last
cycle (a historical restatement inside its own resolution comment, not a new
pending condition). No other stale "waiting on upstream" comment exists
anywhere in the repo.

## Assessment

This run has now swept chart/image currency (11 components directly
verified against real upstream sources this run: Grafana, ArgoCD chart, k3s,
tidb-operator, vault-helm, kargo, external-secrets, KEDA, Istio, Alloy,
Trivy Operator, Valkey, RabbitMQ, redis_exporter), a stale-TODO pattern sweep
(one real hit, fixed), and a doc-index consistency check (one real hit,
fixed) — ten real PRs landed. The remaining gated items are genuinely
blocked on live-cluster facts only the maintainer can observe.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999 — PR #980 is
the maintainer's own live in-progress work toward the first two; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing one of this repo's many tracked ADR flip conditions.

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
