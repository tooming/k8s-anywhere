# ApplicationSet list-generator coverage — preventative guard for the same footgun class as the envoy-egress fix

Janitor sweep (executor.prompt.md STEP 6b fallback chain, 2026-08-07, second cleanup
this run): `networkpolicy-appset.yaml` and `governance-appset.yaml` (RFC #206, RFC
#293) each hand-enumerate a `gitPath:` list-generator that must cover every real
`gitops/**/networkpolicy/` (resp. `gitops/governance/<ns>/`) leaf directory, or that
directory's manifests are never wired to any ArgoCD `Application` and silently never
reach the cluster — structurally the same "hardcoded list drifts from the real thing
it enumerates" shape as `allow-envoy-proxy-backend-egress.yaml`'s namespace list (the
harbor incident, PR #968, and its recurrence for
`tidb`/`longhorn-system`/`istio-system`/`kargo`, closed earlier this same run).

**Verified directly (ADR-0004):** both lists are currently in full sync — cross-
referenced `networkpolicy-appset.yaml`'s 19 `gitPath:` entries plus the 9 standalone
`gitops/platform/*-networkpolicy.yaml` Applications against all 28 real
`gitops/**/networkpolicy/` directories (28/28 covered), and `governance-appset.yaml`'s
23 entries against `gitops/governance/`'s 23 real leaf directories (`base/` correctly
excluded as a shared kustomize base, not a namespace overlay). This is a preventative
guard, not a fix for a live drift — closing the gap before a future namespace addition
repeats the exact class of bug that bit `harbor`.

**Mechanical guard:** new `scripts/appset-list-coverage-check.sh` checks both appsets
in one script (same footgun class, two instances): for each real leaf directory, flags
it if covered by neither the appset's list-generator nor (for networkpolicy only) a
standalone Application. Wired into `make ci` + the GitHub Actions `drift` job (kept in
parity), a `PostToolUse` hook (`scripts/appset-list-coverage-sync-hook.sh`, mirroring
`envoy-egress-allowlist-sync-hook.sh`), and bats coverage in two new scope files
(`tests/drift-appset-list-coverage-check.bats`,
`tests/hook-scripts-appset-list-coverage.bats` — both frozen-monolith parents get new
scopes in their own files per the existing convention).

`make ci` passes (2543 bats tests green, including this check's own coverage).

## PR

https://github.com/tooming/k8s-anywhere/pull/1065
