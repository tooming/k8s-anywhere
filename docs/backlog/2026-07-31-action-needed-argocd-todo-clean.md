# [Action needed] Now/next still gated; ArgoCD floating-tag TODO re-verified, still correct

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Seven real merged PRs so far this run:
[#930](https://github.com/tooming/k8s-anywhere/pull/930) (stale-PR self-review
finish), [#934](https://github.com/tooming/k8s-anywhere/pull/934) (ADR-0028
architect audit → RFC #933), [#935](https://github.com/tooming/k8s-anywhere/pull/935)
(planner absorb into Now/next), [#937](https://github.com/tooming/k8s-anywhere/pull/937)
(cert-manager `1.21.0` → `1.21.1` bump), [#936](https://github.com/tooming/k8s-anywhere/pull/936)
(stale sync/* PR rebase + ADR-0024 status-header doc-drift fix),
[#938](https://github.com/tooming/k8s-anywhere/pull/938) (branch-prefix regex
recurrence-guard fix, found while unblocking #936), [#939](https://github.com/tooming/k8s-anywhere/pull/939)
(prior-cycle doc-consistency record). No overlap between any of these.

## This cycle's fresh angle

Grepped `infra/`, `gitops/`, and `scripts/` for untracked `TODO`/`FIXME`/`XXX`
markers (a lens not yet used this run — every prior sweep this run targeted
ADR flip conditions, chart-pin currency, or doc-drift cross-checks, not inline
code TODOs). Found exactly one real candidate:
`infra/modules/argocd/values.yaml:14`'s `global.image.tag: latest` override,
with an inline TODO: "drop this override once argo-cd chart >= the version
that ships the expose-appset-ui commit (#26666)."

Verified directly against the real `argoproj/argo-cd` repository (not training
knowledge, ADR-0004): the commit is `4d02fc2f5` ("feat: expose Appset UI and
fix pie chart summary (#26666)"), reachable from `origin/master` but **not**
an ancestor of `v3.4.5` (the newest stable tag, matching this repo's pinned
chart `10.2.1`) — confirmed via `git merge-base --is-ancestor`. Being a `feat:`
commit, it targets the next minor release, not a `3.4.x` patch backport; no
`v3.5.0` or later stable tag exists yet (`v3.4.5` is the newest). The TODO's
condition is genuinely not met — the `latest` tag override is still correctly
needed, not a stale/forgotten TODO.

Also checked the RFC #785 `networkPolicy.create: false` override immediately
below it (chart 10.x flipped this key's upstream default) — still correctly
set, no drift. And a nearby comment citing "pinned chart version
(argo-cd-9.7.1)" (line 25) is a historical record of what was verified when
PR #493 landed (before a later bump to `10.2.1`), not a live-tracked
assertion — not doc drift, same pattern as `docs/done/` entries retaining
old version numbers.

No actionable gap found on this lens this cycle.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) an ArgoCD `v3.5.0+` stable
release actually shipping the `expose-appset-ui` commit, which would make the
`latest` tag override droppable — worth a follow-up check on a future
upgrade-drafter/architect pass, not actionable today.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
