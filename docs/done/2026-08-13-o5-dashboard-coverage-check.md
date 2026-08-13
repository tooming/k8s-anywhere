# Add the CHARTER Objective O5 dashboard-coverage drift check that never existed

Autonomous JANITOR-fallback run (`executor.prompt.md` STEP 6b, item 6 — no
feature/plan/arch/upgrade/sync/triage work remained this cycle: the ROADMAP
Now/next lane was fully gated, no ungroomed issues existed, and this run's
prior cycles had already exhausted the obvious currency-sweep angles
(`gitops/**/*.yaml`, the Terraform-bootstrap seam, the two `docker-compose.yml`
stacks)). Found while re-reading `CHARTER.md`'s Objectives for a fresh
gap-analysis angle: **O5's own text promises "Measured by: a drift check wired
into `make ci`" — no such check actually existed.** `readme-check.sh` and
`lab-ui-check.sh` check adjacent but different things (README/Makefile sync;
the "Lab UIs" panel vs. HTTPRoutes); neither cross-references
`gitops/platform/`'s auto-synced Applications against
`grafana/dashboards/lab-<name>.json`.

Before writing the check, verified (not assumed, ADR-0004) whether the
underlying coverage claim was actually true: enumerated every `gitops/platform/`
`Application` with a real (uncommented) `automated:` syncPolicy key, excluded
plumbing companions (`*-extras`/`*-networkpolicy`/`*-config`/`*-resources`/
`*-certificate`/`*-schedules`/`*-policies`/`*-root-ca`/`*-scaling`/`lab-gateway`
— no metrics of their own), and cross-checked the remaining 28 real components
against `grafana/dashboards/`. Coverage was already complete — including three
components (`kro`/`moto`/`ack-s3`) consolidated into one shared
`lab-cloud-control-plane.json` and a few Application-name-vs-dashboard-name
aliases (`envoy-gateway` → `lab-envoy.json`, `kube-state-metrics` →
`lab-ksm.json`, `trivy-operator` → `lab-trivy.json`, `argocd-extras` →
`lab-argocd.json`). So this is closing an **enforcement** gap, not a coverage
gap — the same "missing recurrence guard" class CLAUDE.md's bugfix rule and
the JANITOR role both call out as the highest-value cleanup.

## Fix

Added `scripts/o5-dashboard-coverage-check.sh`: an explicit
Application-name → dashboard-basename allowlist (mirrors
`tests/governance.bats`'s `STANDARD_NS` pattern, since a shared dashboard and
name aliases rule out a name-guessing heuristic), with two checks — (1) every
mapped component's dashboard file actually exists; (2) a coverage loop over
`gitops/platform/*.yaml` failing if a *new* auto-synced, non-plumbing
Application shows up with no entry in the map, so a future component can't
silently skip its O5 dashboard the way this run found the check itself
missing. Wired into `Makefile`'s `o5-dashboard-coverage-check` target and the
`ci` target (right after `lab-ui-check`), and into
`.github/workflows/ci.yml`'s `drift` job in the same position (kept in parity
per `scripts/ci-parity-check.sh`, which the `ci-parity-sync-hook.sh`
PostToolUse hook confirmed live during this edit). New
`tests/drift-o5-dashboard-coverage-check.bats` (`tests/drift-detectors.bats`
is frozen — new drift-check scopes get their own file): passes on the real
repo; fails when a mapped dashboard is missing (fixture); fails when a new
auto-synced Application has no mapping (constructed at `$BATS_TEST_TMPDIR`
runtime, avoiding a 28-dummy-file static fixture); does not flag an on-demand
(non-`automated:`) Application; does not flag a `-extras`-suffixed plumbing
Application. All four scenarios manually verified against the real script
before committing (bats itself isn't installed in this clusterless session).

## Behavior preservation

Additive only — a new script, a new Makefile target, one new line each in
`Makefile`'s `ci` target and `.github/workflows/ci.yml`'s `drift` job, and a
new bats file. No existing check's behavior changed; `make ci` passes clean
against the real repo (the new check reports zero drift, confirming the
coverage-completeness verification above).

## PR

https://github.com/tooming/k8s-anywhere/pull/1192
