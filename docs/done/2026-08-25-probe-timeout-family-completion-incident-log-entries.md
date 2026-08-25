# docs: complete the probe-timeout incident family — envoy-gateway resolution, harbor-database SIGPIPE, cert-manager+KEDA audit

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's tenth cycle. "Now / next" remains fully gated (issue
#633, unchanged) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER were re-confirmed unchanged. **No prerequisites — executor may pick
up immediately.**

## What happened

While syncing `main` this cycle, found that an interactive/human session had
merged PR #1333 (`fix(envoy-gateway): probe timeoutSeconds too tight (153
restarts/13d)`) — the exact root cause of the "Unresolved" Envoy Gateway xDS
control-plane connectivity incident this run's cycle 5 (PR #1329) logged.
Reading PR #1333's body surfaced two more previously-undiscovered incidents
of the same class, cited in its own text and confirmed live in the repo:

- **PR #1121** (2026-08-11): `harbor-database`'s 5s probe timeout (from the
  earlier PR #1040 fix) was *still* too tight — killing the healthcheck
  script mid-exec produced a fatal SIGPIPE in postgres, triggering a full
  crash-recovery cycle roughly every minute. This is what was actually
  root-causing `harbor-core`'s "endless connection failures" that multiple
  earlier sessions couldn't explain.
- **cert-manager + KEDA** (2026-08-11, a dedicated "systemic probe-timeout
  audit" session, per both charts' own inline comments): the same
  `timeoutSeconds: 1` chart default, swept and fixed for both in one pass.

## What was checked before logging

Confirmed all three fixes are live: `gitops/envoy-gateway/` (new Kustomize
overlay), `gitops/platform/cert-manager.yaml`/`keda.yaml` (both carry
`timeoutSeconds: 15` with matching inline comments). Read PR #1121's and
PR #1333's actual bodies rather than paraphrasing from memory.

## The fix

- Updated the existing "Unresolved" envoy-gateway xDS row's Fix/Time-to-
  resolve/Follow-up columns to record the resolution (PR #1333), explicitly
  noting the row's own prior "likely apiserver/datastore write pressure"
  theory was reasonable but wrong (ADR-0004: correct the record, don't
  quietly delete a wrong guess).
- Added three new rows: envoy-gateway probe-timeout (PR #1333), harbor
  -database SIGPIPE (PR #1121), cert-manager+KEDA audit. This brings the
  documented probe-timeout-footgun family to seven components across eight
  incidents (Harbor ×2, ArgoCD, Kyverno, cert-manager, KEDA, Envoy Gateway).
- Four new/updated bats assertions in `tests/incident-log.bats`.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1337
