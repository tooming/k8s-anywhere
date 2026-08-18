# verifyImages ClusterPolicy — Audit → Enforce flip

CHARTER **Objective O4**, RFC #214 Item 3; executor pickup 2026-08-18, third cycle this
run — reached via `executor.prompt.md` STEP 6b after UPGRADE-DRAFTER (PR #1221) and
JANITOR (PR #1222) fallback deliverables, when STEP 1's fresh open-issues check found
the gating `[Action required]` issue #631 had just received its confirmation comment
mid-run. **Prerequisites satisfied:** `auto/cosign-ci-sign-step` was already merged (the
`sign-image` job exists in `.forgejo/workflows/build-sign-push.yml`, carried over from
the ADR-0035 CI-source migration) and the maintainer's live-cluster confirmation landed
in issue #631 at 2026-08-18T05:32:37Z: a Forgejo Actions run (#29 attempt 2, commit
`b388df5c`) completed the `sign-image` job green, independently verified (not just the
workflow's own status, ADR-0004) via Harbor's own artifact API showing a real
`type: signature.cosign` accessory attached to `harbor.127.0.0.1.nip.io/library/hello`
(digest `sha256:2f9ca51a...`, subject `sha256:91d52ea9...`, created
`2026-08-18T05:30:10Z`). This is a genuinely different verification path than the
item's original `crane ls`/curl suggestion, but satisfies the same underlying ask (a
real signed image confirmed in Harbor) — the confirming comment is the maintainer's own
interactive-session finding, not this executor's own live-cluster check (this remote
session remains clusterless).

## What changed

Edited `gitops/kyverno/policies/verify-image-signatures.yaml`:
`validationFailureAction: Audit` → `Enforce`; `failurePolicy: Ignore` → `Fail`; updated
the file's header comment and the `policies.kyverno.io/description` annotation to
describe the new Enforce state and cite the confirming evidence chain.

Extended `tests/kyverno.bats` (this repo's existing convention keeps
`verify-image-signatures` coverage there, not a separate `kyverno-policies.bats`):
retitled the Audit/Ignore assertions to assert `Enforce`/`Fail`, and added two "does not
pin the stale Audit/Ignore" recurrence guards (mirroring this repo's own bump-guard
convention — e.g. the ArgoCD chart-pin and ADR-0034 Tempo-row guards landed earlier this
same run).

## Rollback path

Revert both fields to `Audit` + `Ignore` and push — ArgoCD syncs the reverted policy
within 30s (per RFC #214 §"Rollback path"), no cluster downtime. `background: false`
means the policy only evaluates admission requests, not existing pods, so a revert
takes effect on the next admission without needing to touch already-running workloads.

## Caveats (ADR-0004)

This remote clusterless session cannot verify a live Kyverno admission-controller
reload actually applies the new Enforce/Fail behavior correctly, nor that every
Harbor-sourced Pod in the live cluster (capstone's `hello` deployment/rollout) is
currently signed and would pass admission post-flip — the confirming evidence (issue
#631) establishes that at least one signed image exists, not that every live
Harbor-sourced Pod spec is already covered. If an unsigned Harbor-sourced Pod is
currently running or gets rescheduled, this flip could newly block it at admission —
the rollback path above is the mitigation if that's observed live.

`make ci`: green (bats installed this session via `apt-get`; full local suite clean,
including all `tests/kyverno.bats` assertions).

## PR

https://github.com/tooming/k8s-anywhere/pull/1223
