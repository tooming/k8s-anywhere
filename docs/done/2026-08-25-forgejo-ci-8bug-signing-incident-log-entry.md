# docs: log the 8-bug Forgejo CI signing incident (PR #1213)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's ninth cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes found nothing new this cycle
either. **No prerequisites — executor may pick up immediately.**

## The gap

The final, largest real incident from this run's mining of issue #631's
comment history: the 2026-08-18 session that finally landed a real signed
image in Harbor, closing out 20 days of prior investigation (Cilium drift,
Vault sealed, missing GitLab/Forgejo runner, disk pressure, NetworkPolicy
port mismatch, two silent Helm no-ops, host CPU exhaustion — all already
logged in prior cycles this run). That session found and fixed **eight**
distinct, previously-undiscovered bugs, each masking the next, to get from
"still broken after everything else" to a verified `signature.cosign`
accessory in Harbor. This is the single richest incident in the whole
history and was never logged.

## The fix

Added one consolidated row (2026-08-18, **P2** — matching the existing
2026-08-04 "GitLab CI (no runner ever registered)" row's classification for
a CI/pipeline-functionality gap, not a core always-on component) rather
than eight separate rows — all eight bugs were found and fixed in one
investigative arc culminating in one PR (#1213), and itemizing each as its
own row would fragment a single story. Lists all eight bugs concisely
(QEMU emulation, a missing storage-namespace NetworkPolicy rule, a
cluster-internal-only S3 redirect, unreachable `docker.io` auth, non-root
cosign breaking `/etc/hosts`, unreachable Sigstore TUF config, and the
`--allow-insecure-registry` HTTPS/HTTP gap) and cites the independent
verification method (Harbor's own artifact API, not just the workflow's
own success status — ADR-0004) and the 24 new bats assertions PR #1213
itself added. Added a matching coverage test in `tests/incident-log.bats`.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1318
