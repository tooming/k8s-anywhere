# README.md Endpoints table — add missing Harbor + TiDB demo rows, guard against recurrence

Executor-fallback JANITOR pass (`executor.prompt.md` STEP 6b, fourteenth cycle,
2026-08-10), via a fifth delegated deep gap-analysis sweep. README.md's `##
Endpoints` table — the canonical, human-facing list of UIs served through the
`:8000` front door — was missing two on-demand components with real, live
`HTTPRoute`s: Harbor (`harbor.127.0.0.1.nip.io`) and TiDB demo
(`tidb-demo.127.0.0.1.nip.io`). Both were already correctly listed in Grafana's
"Lab UIs" panel (mechanically enforced by `scripts/lab-ui-check.sh`), but that
check only ever compared the panel against `gitops/` HTTPRoutes, never README.md's
own table — so this list had no guard and had silently gone stale.

## What changed

- Added Harbor and TiDB demo rows to README.md's Endpoints table.
- Extended `scripts/lab-ui-check.sh` to also compare README.md's `## Endpoints`
  section (scoped via `awk`, so a stray host-like string elsewhere in the doc is
  never mistaken for an endpoint row) against the same `gitops/` HTTPRoute source
  of truth already used for the Grafana panel.
- New fixture trees `tests/fixtures/lab-ui-check/{readme-missing,readme-stale}/`
  and two new `@test` cases in `tests/drift-detectors.bats`.
- `scripts/lab-ui-sync-hook.sh` (PostToolUse companion) now also reacts to
  README.md edits, not just `stack-health.json`/HTTPRoute manifests. New `@test`
  case in `tests/hook-scripts-coverage.bats`.
- `make drift-detectors-tests-mark` / `make hook-scripts-coverage-tests-mark` run
  to refresh both frozen-monolith snapshots (adding tests to an existing scope
  within each monolith, not a new drift-check type).

## Verification

`bash scripts/lab-ui-check.sh` passes against the real repo; both new fixture
trees independently verified to fail with the correct message before the fix and
pass after; `make ci` green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1095
