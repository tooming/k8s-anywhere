# docs: log the Harbor (PR #1040) and argocd-repo-server (PR #1103) probe-timeout incidents

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's seventh cycle. "Now / next" remains fully gated (issue
#633, unchanged) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER were re-confirmed unchanged from cycles 3–4. **No prerequisites —
executor may pick up immediately.**

## The gap

Cycle 6 (PR #1330) logged Kyverno's 2026-08-11 instance of the "chart-default
probe timeout too tight for this host" bug class, citing sibling fixes PR
#1040 (Harbor) and PR #1103 (ArgoCD repo-server) that were never given their
own rows. Fetched both PRs directly (not assumed) to log them accurately:

- **PR #1040** (2026-08-06): the `goharbor/harbor` chart hardcodes
  `timeoutSeconds: 1` for every component's probes — self-inflicted cascading
  crashloops under any real load on this host. Fixed: 15 probe overrides to
  5s.
- **PR #1103** (2026-08-10): `argocd-repo-server` crashlooping continuously
  for 24h+ (54+ restarts) — the 5s probe timeout was too tight for sustained
  (not just cold-start) host latency, cancelling in-flight healthz requests.
  This is the most severe instance of the class: unlike Harbor/Kyverno (a
  single on-demand/next-wave component), a crashlooping `repo-server` blocks
  ArgoCD's reconcile loop for the *entire* always-on stack.

Together with Kyverno, this is now a fully-documented three-incident trail
for the same bug class, with the mechanical guard (`scripts/probe-timeout-
check.sh`) that eventually closed it generically.

## The fix

Added two rows to `docs/incident-log.md`, chronologically placed (Harbor
2026-08-06, ArgoCD 2026-08-10) and cross-referenced against the existing
Kyverno row and each other. Two new matching bats assertions in
`tests/incident-log.bats`.

`make ci`: full local run, real `bats`, 0 failures.

## PR

https://github.com/tooming/k8s-anywhere/pull/1331
