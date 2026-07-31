# [Action needed] Now/next still gated; cert-manager 1.21.1 doc-consistency check clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: both still open, no new confirmation.

## What this run already did

Eight real merged PRs this run:
[#903](https://github.com/tooming/k8s-anywhere/pull/903) (kustomize orphan-file
guard), [#905](https://github.com/tooming/k8s-anywhere/pull/905) (tidb-demo
dashboard coverage), [#921](https://github.com/tooming/k8s-anywhere/pull/921)
(Oracle retry doc-drift), [#927](https://github.com/tooming/k8s-anywhere/pull/927)
(context-doc-version-sync hook), [#929](https://github.com/tooming/k8s-anywhere/pull/929)
(Velero namespace-list doc-drift), [#930](https://github.com/tooming/k8s-anywhere/pull/930)
(Kyverno replica-count doc-drift), [#932](https://github.com/tooming/k8s-anywhere/pull/932)
(CHARTER O3 namespace-count doc-drift), [#936](https://github.com/tooming/k8s-anywhere/pull/936)
(ADR-0024 stale status header). A concurrent executor session was also active
all day, independently shipping the Cilium EOL bump, a Kyverno fail-closed
replica fix, a stale-PR mechanical guard, a cert-manager 1.21.1 bump, and
several clean audit sweeps — no overlap with this session's fixes.

## This cycle's fresh angle (clean)

Applied this run's own "cross-check a recent multi-file change against every
doc that describes it" technique to the just-merged cert-manager `1.21.0` →
`1.21.1` bump (#937, from the concurrent session). Checked every doc that
could plausibly cite cert-manager's version (`README.md`,
`docs/00-architecture.md`, `docs/dependency-tree.md`,
`docs/decisions/context.md`, `CHARTER.md`) — this time it's fully clean:
`docs/dependency-tree.md` already cites `v1.21.1` correctly (updated in the
same bump PR), `gitops/platform/cert-manager.yaml`'s `targetRevision` matches,
and ADR-0028's own Re-evaluation log entry (2026-07-31) is complete and
consistent with the live pin. Unlike the four prior doc-drift finds this run
(Velero namespace count, Kyverno replica count, CHARTER O3 count, ADR-0024
status header), this bump's own PR correctly updated every doc that needed it
— no gap found.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle
per `executor.prompt.md` STEP 8; this is not a stopping point.
