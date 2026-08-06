# [Action needed] Now/next still gated; UPGRADE-DRAFTER-angle infra/ sweep clean, one citation correction made

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items every
cycle this run has found gated — [#631](https://github.com/tooming/k8s-anywhere/issues/631)
and [#633](https://github.com/tooming/k8s-anywhere/issues/633), both
unchanged since the last check this run (updated_at still 2026-08-06 07:38
UTC, comment count still 5 on each). 0 open PRs.

## This run's real output so far

Six PRs landed this session: `plan/loki-3-7-6-currency` (#1041),
`auto/loki-3-7-6` (#1042), `plan/grafana-13-0-5-tempo-log-drift` (#1043),
`auto/grafana-image-13-0-5` (#1044), an `[Action needed]` record (#1045),
and `arch/w32-digest-refresh-grafana-loki` (#1046).

## This cycle's fresh angle

Per `upgrade-drafter.prompt.md` STEP 2's own guidance — a distinct
enumeration pass over `infra/modules/**/*.tf` + `infra/live/**/*.hcl` for
Terraform-bootstrapped Helm charts, separate from the `gitops/**/*.yaml`
walk this run's prior cycles already did exhaustively. Grepped
`infra/modules/` for `chart_version`/`helm_release`: only
`infra/modules/argocd/` defines one (the `argo-cd` chart). That pin is
already at `10.2.3` — confirmed already current and already landed
(`docs/done/2026-08-05-argocd-chart-10-2-3.md`), not a new gap.

**Self-correction:** this run's own earlier PR bodies (#1041, #1043) cited
"the still-open ArgoCD Terraform-chart `10.2.2`→`10.2.3` diligence... as
unresolved", inherited from the 2026-08-05 planner note without
re-verifying it against current state. That citation was stale by the time
this run started — a *later* 2026-08-05 cycle had already resolved it
(`docs/done/2026-08-05-argocd-chart-10-2-3.md` exists, ROADMAP's item is
`[x]`). No functional drift resulted (this run never acted on the stale
citation), but flagging the citation error honestly here rather than
silently letting it propagate into a future cycle's own "what's still
open" list — this note is the correction; no further code or PR-body edit
needed since the earlier PRs are already merged.

## Assessment

No new buildable Now/next work found. The three gated items remain blocked
on the same live-cluster facts only a hands-on session can supply.

## What would unblock further work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub
issue (intake); (c) a new upstream release/CVE firing a tracked flip
condition.

Per `executor.prompt.md` STEP 8 this is not a stopping point — the run
continues to the next cycle.
