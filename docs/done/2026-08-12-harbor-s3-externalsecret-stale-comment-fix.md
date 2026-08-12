# Fix stale comment in harbor-s3-externalsecret.yaml — referenced a removed field

(CHARTER **Core Values** §"Everything as code" / §"Decisions written down"; JANITOR-fallback
bounded cleanup 2026-08-12, reached via `executor.prompt.md` STEP 6b — the Now/next lane
was re-confirmed fully gated (six items, unchanged, still blocked on unconfirmed standing
issues #631/#633, both re-checked directly this cycle: still open, no new comment since
2026-08-11), and this cycle's own attempts at the PLANNER, ARCHITECT, UPGRADE-DRAFTER,
DOC-DRIFT-AUTHOR, and TRIAGER all came up empty (same reasoning as the immediately
preceding cycle's `docs/done/2026-08-12-dashboard-metric-drift-fix-alloy-grafana.md`
entry — nothing changed between the two cycles) — fell through to JANITOR. No
prerequisites — executor may pick up immediately.)

## What was wrong

Cross-checking every `gitops/secrets/*-externalsecret.yaml` file's header comment against
its actual consuming manifest (a fresh angle this cycle, after the dashboard-audit series
completed): `gitops/secrets/harbor-s3-externalsecret.yaml`'s header comment still said the
Secret's env vars are "injected via `registry.registry.extraEnvVarsSecret: harbor-s3-creds`
in `gitops/platform/harbor.yaml`". That field name was removed from `harbor.yaml` days ago —
`gitops/platform/harbor.yaml`'s own detailed comment (added in PR #1114, 2026-08-11)
explains that `extraEnvVarsSecret` was never a real field in the `goharbor/harbor` chart
(verified directly against the chart's templates at the time — zero matches for that
string anywhere under `templates/registry/`) and was silently ignored by Helm the entire
time it sat there, which is the actual root cause behind issue #631's repeated push
failures. The fix switched to `extraEnvVars[].valueFrom.secretKeyRef` against the same
`harbor-s3-creds` Secret — but the sibling file that *renders* that Secret
(`harbor-s3-externalsecret.yaml`) never got its own header comment updated to match, so it
still described the broken, no-longer-present mechanism.

The `ExternalSecret` resource itself was verified correct and unaffected — the Vault path
(`secret/harbor/s3`, seeded by `scripts/garage-bootstrap.sh`, not `vault-bootstrap.sh` —
also verified directly against that script) and property names (`access-key-id` /
`secret-access-key`) both match what `garage-bootstrap.sh` actually writes. This was a
comment-only drift, not a functional bug — `harbor.yaml`'s own PR #1114 fix already
carries a bats regression guard (`tests/harbor.bats` asserts `extraEnvVarsSecret:` is
absent from `harbor.yaml`).

Also swept the other `gitops/secrets/*.yaml` files' header comments
(`harbor-admin-externalsecret.yaml`'s `existingSecretAdminPassword`/
`existingSecretAdminPasswordKey` claim, `kargo-admin-externalsecret.yaml`'s `envFrom.
secretRef` claim) against their real consuming manifests — both verified accurate, no
further drift found. Checked `gitops/` for any other stray `extraEnvVarsSecret` or
`artifactory` references outside historical `docs/done/`/`docs/backlog/` narrative
records (which are intentionally point-in-time and not corrected) — none found.

## Fix

`gitops/secrets/harbor-s3-externalsecret.yaml`'s header comment now describes the real,
current mechanism (`extraEnvVars[].valueFrom.secretKeyRef`) and points at
`harbor.yaml`'s own comment for the full root-cause history, instead of the removed
`extraEnvVarsSecret` field name.

## Recurrence prevention

This is a comment-only fix with no behavioral surface to guard mechanically — the actual
functional bug this comment described (the removed field) already has a bats regression
guard in `tests/harbor.bats` (added alongside PR #1114). A stale-comment class like this
one is inherently hard to guard against structurally (there's no way to assert a comment
"matches" a sibling file's behavior without parsing prose), so this fix relies on the same
diligence this cycle applied — cross-checking each Secret-rendering file's claims against
its real consumer at pickup time, mirroring the existing due-diligence pattern used for
version-pin bumps in this repo (re-verify at pickup time, don't just trust a cached
description).

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration items;
`verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone Deployment
removal on unconfirmed issue #633) — re-checked directly, both still open, no new comment
since 2026-08-11.

## ADR-0004 caveat

The corrected comment was verified against real, already-merged code in this repo
(`harbor.yaml`'s own PR #1114 fix and its detailed root-cause comment, `garage-bootstrap.sh`'s
actual Vault-write commands) — not assumed. This remote clusterless session cannot verify
Harbor's registry actually reads these env vars successfully against a live pod; that
verification already happened in a prior live-cluster session per issue #631's comment
history and is unaffected by this comment-only change.

## Rollback path

Revert this commit — a single comment-block edit in one YAML file, no functional/schema
change, no other surface affected.

## PR

(filled in after PR creation)
