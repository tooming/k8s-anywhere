# docs: log the Kyverno admission-controller probe-timeout incident

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's sixth cycle. "Now / next" remains fully gated (issue
#633, unchanged) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER were re-confirmed unchanged from cycles 3–4. **No prerequisites —
executor may pick up immediately.**

## The gap

Another real, undocumented incident from issue #631's comment history
(2026-08-11 session, the same session that fixed the `harbor-registry`
S3-credentials `extraEnvVarsSecret` bug already logged): Kyverno's
admission-controller webhook — fail-closed, blocks all cluster mutations
when unhealthy — was crashlooping on the chart's default 1-second startup
-probe timeout, itself intermittently blocking ArgoCD from applying the
Harbor S3-creds fix. Distinct root cause and distinct component from the
Harbor row already logged for the same session; never had its own entry.

## What was checked before logging it

Verified the fix is still live: `gitops/platform/kyverno.yaml`'s
`startupProbe`/`livenessProbe`/`readinessProbe` all carry `timeoutSeconds:
15` today, with an inline comment matching the issue-comment account exactly
(cites PR #1040/#1102/#1103 as the same footgun class in Harbor/ArgoCD).
Confirmed this bug class already has a mechanical guard —
`scripts/probe-timeout-check.sh` ("probe-timeout sanity", wired into
`make ci`) asserts every explicit probe in `gitops/`/`infra/` has
`timeoutSeconds >= 5s` — so logging this incident doesn't also require
adding a new guard; it already exists (a future PR that reintroduces a
sub-5s timeout, this one included, already fails CI).

## The fix

Added one row (2026-08-11, **P1** — an admission-controller failure is
security-relevant per this repo's own severity scheme, and the webhook is
fail-closed cluster-wide), inserted next to the same-session Harbor
S3-creds row for chronological locality. Cites the exact `describe pod`
evidence (788 failures over 3d10h on one replica) and the existing
mechanical guard. Added a matching bats assertion
(`tests/incident-log.bats`).

`make ci`: green (full local run including real `bats`).

## PR

<!-- filled in after opening the PR -->
