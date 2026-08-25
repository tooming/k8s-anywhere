# docs: log two harbor-registry silent-Helm-no-op incidents (PR #1114, commits 38cebf0/9fd14c8)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's eighth cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes found nothing new this cycle
either. **No prerequisites — executor may pick up immediately.**

## The gap

Continuing this run's mining of issue #631's comment history: two more
real, undocumented incidents, both already fully documented in
`gitops/platform/harbor.yaml`'s own inline comments, both the same failure
class (a Helm values key silently ignored because it doesn't match the
chart's real schema) hitting the same component (`harbor-registry`) two
days apart.

## The incidents

1. **2026-08-11 — S3 credentials never applied.** `registry.registry.
   extraEnvVarsSecret` isn't a real field in the `goharbor/harbor` chart
   (confirmed directly against the chart's templates — zero references).
   Helm silently ignored it, so the registry's S3 access/secret keys were
   never actually injected — every push failed with `NoCredentialProviders`.
   Fixed in PR #1114 using the chart's real `extraEnvVars` +
   `valueFrom.secretKeyRef` mechanism.
2. **2026-08-13 — registry OOMKilled mid-push.** The `resources:` key for
   the registry container was nested one level too shallow
   (`registry.resources` instead of `registry.registry.resources`), so no
   memory limit had ever actually applied — a real `docker push` OOMKilled
   the container mid-blob-upload. Fixed live via commits `38cebf0`/`9fd14c8`
   (bump 512Mi→1Gi + correct the nesting).

## The fix

Added both as new rows (2026-08-11, 2026-08-13, both **P1**) to
`docs/incident-log.md`, positioned chronologically right before the
existing 2026-08-11 P0 datastore row. Verified both citations (PR #1114,
commits `38cebf0`/`9fd14c8`) against `git log` before writing them in —
caught and fixed one fabricated commit-message citation during self-review
(had written a plausible-sounding but invented commit subject for the
extraEnvVarsSecret fix; corrected to the real PR #1114 reference). Added
two matching bats coverage tests.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1317
