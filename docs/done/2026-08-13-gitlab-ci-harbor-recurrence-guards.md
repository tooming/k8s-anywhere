# Recurrence guards for the 2026-08-13 live-cluster #631 hotfixes

JANITOR-fallback cleanup (`executor.prompt.md` STEP 6b), reached after the
executor's own Now/next lane was found fully gated: all six standing unchecked
ROADMAP items (three GitLab→Forgejo migration items requiring a live-cluster
session; three items gated on maintainer-confirmation issues #631/#633, both
re-checked and still unconfirmed) with no live-state-safe slice to split off
any of them. No open issues to triage (only the two standing #631/#633
`[Action required]` issues, neither actionable from a clusterless session).

## What this closes

A same-day live-cluster interactive session (per issue #631/#633's comment
history) pushed three real, verified hotfixes directly to `main` while
investigating #631 (docker push / signed-image confirmation):

- `788bbaf` — `.gitlab-ci.yml`: added a `retry_cmd()` bash wrapper (6 attempts,
  15s backoff) around `build-and-push`'s network-facing docker
  build/push commands, plus GitLab's native `retry: 2` as a whole-job
  fallback on both `build-and-push` and `sign-image`.
- `26a48a7` — `gitops/harbor/route.yaml`: added a `timeouts:` block (60s
  `request`/`backendRequest`) to the Harbor `HTTPRoute` — Envoy Gateway's
  ~15s default was too tight for `harbor-core` proxying a cold registry
  connection under this host's real load, causing every blob-upload POST to
  504.
- `d34922c` — `.gitlab-ci.yml`: moved `retry_cmd`'s definition from `script:`
  into `before_script:` so `docker login` (the first network call) is
  wrapped too — it had been hitting the same transient "context deadline
  exceeded" class reaching Harbor's token endpoint.

All three are real, live-verified fixes (see the linked issue comments) —
this PR does not change their behavior. But per CLAUDE.md's "every bugfix
must prevent recurrence" rule, a direct-to-`main` commit skips the PR path
these fixes would otherwise land through, and none of the three added bats
coverage. Without a mechanical guard, a future edit could silently drop the
retry wrapper, move it back into `script:` (reintroducing the exact
login-not-covered bug the third commit fixed), or drop the route's
`timeouts:` block — reintroducing the near-total blob-upload failure rate
found live — with nothing in `make ci` catching it.

## What changed here

- `tests/harbor.bats` — new assertion: the Harbor `HTTPRoute` sets
  `timeouts:` with `request: 60s` and `backendRequest: 60s`.
- `tests/capstone.bats` — three new assertions: `retry_cmd` is defined in
  `build-and-push`'s `before_script:` (not `script:`); `docker login`,
  `docker build`, and both `docker push` calls are wrapped in `retry_cmd`;
  both `build-and-push` and `sign-image` set `retry: 2`.

Behavior-preserving — no manifest or pipeline logic changed, only new
recurrence-guard test coverage for already-merged fixes.

## ADR-0004 caveat

This is a clusterless session; the three source fixes were already verified
live by the session that made them (see issue #631's 2026-08-13 comment).
This PR only adds structural (`grep`-based) test coverage confirming the
fixes are present on disk as described — it does not re-verify them against
a live cluster.

## PR

https://github.com/tooming/k8s-anywhere/pull/1186
