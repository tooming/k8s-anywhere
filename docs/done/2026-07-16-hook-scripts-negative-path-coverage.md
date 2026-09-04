# Hook-scripts negative-path coverage — `argocd-crd-ssa-sync-hook.sh` + `helm-chart-pin-sync-hook.sh`

(CLAUDE.md's "every bugfix/gap prevents recurrence" ethos + ROADMAP rule #9's
coverage/hardening sweep; follow-up flagged by
`docs/done/2026-07-16-hook-scripts-bats-coverage.md`, which closed bats coverage for
13 previously-untested hook scripts but left these two with only filter + real-repo
happy-path coverage, noting their underlying checks are "network-tolerant with no
hook-level file-scoped override for injecting a broken fixture." That note is
incomplete: both underlying `*-check.sh` scripts already have offline test seams used
by `tests/drift-detectors.bats` — `helm-chart-pin-check.sh` supports
`CHARTPINCHECK_ROOT` + a `CHARTPIN_RESOLVER` stub (fixtures already exist at
`tests/fixtures/helm-chart-pin/{drift,in-sync}/`); `argocd-crd-ssa-check.sh` supports
`CRDSSA_CHECK_ROOT` + a `CRDSSA_RENDERER` stub (fixtures already exist at
`tests/fixtures/argocd-crd-ssa/{drift,in-sync}/`). Since each hook simply
`bash`-invokes its check script in the same shell (no `env -i`), exported
`CHARTPIN_RESOLVER`/`CRDSSA_RENDERER` env vars propagate straight through — no new
fixtures need to be built, just two more `@test` cases in
`tests/hook-scripts-coverage.bats`: (1) for `argocd-crd-ssa-sync-hook.sh`, run with
`CRDSSA_RENDERER="$REPO/tests/fixtures/argocd-crd-ssa/renderer-stub.sh"` and a payload
pointing at `tests/fixtures/argocd-crd-ssa/drift/big-app.yaml` (oversized CRD, no
`ServerSideApply=true`) — assert exit 2 and that stderr names the offending
Application; (2) for `helm-chart-pin-sync-hook.sh`, run with
`CHARTPIN_RESOLVER="$REPO/tests/fixtures/helm-chart-pin/resolver-stub.sh"` and a
payload pointing at `tests/fixtures/helm-chart-pin/drift/gitops/apps.yaml` (a
`*-missing` pinned version) — assert exit 2 and that stderr names the bad pin. No
script changes — tests only. `make ci` must pass. `docs/done/` entry required.
**No prerequisites — executor may pick up immediately.**
(auto/hook-scripts-negative-path-coverage)

## Deviation from the item's literal plan

The item's plan for `argocd-crd-ssa-sync-hook.sh` — feed the hook a payload whose
`file_path` points directly at `tests/fixtures/argocd-crd-ssa/drift/big-app.yaml` —
does **not** actually exercise the drift branch. The hook has its own explicit guard:

```sh
# tests/fixtures/ holds deliberately-broken examples for the drift detectors — skip.
case "$fp" in */tests/fixtures/*) exit 0 ;; esac
```

Any `file_path` under `tests/fixtures/` short-circuits to `exit 0` before the
`CRDSSA_RENDERER`-backed check ever runs — confirmed by running the hook against the
literal fixture path with the renderer stub wired in: it exits 0 regardless of the
fixture's content. Following the item's plan verbatim would have produced a test that
passes today but can't actually detect a regression in the drift-check logic (it would
pass even if the underlying check were deleted).

Fixed by copying `tests/fixtures/argocd-crd-ssa/drift/big-app.yaml` into
`$BATS_TEST_TMPDIR` (outside the `tests/fixtures/` skip path) before invoking the hook,
then pointing the payload at that copy. This actually drives the hook through
`CRDSSA_CHECK_FILES` → `argocd-crd-ssa-check.sh` → the `CRDSSA_RENDERER` stub → the
oversized-CRD-without-SSA failure path, and asserts exit 2 with the offending
Application name (`bigcrd-app`) in the output.

`helm-chart-pin-sync-hook.sh` has no equivalent guard, so its test follows the item's
plan as written: payload points straight at
`tests/fixtures/helm-chart-pin/drift/gitops/apps.yaml` with `CHARTPIN_RESOLVER` set to
the resolver stub; asserts exit 2 with `bad-pin` in the output.

## What changed

- `tests/hook-scripts-coverage.bats`: two new `@test` cases —
  `argocd-crd-ssa-sync-hook: an oversized-CRD Application without ServerSideApply exits
  2 (drift)` and `helm-chart-pin-sync-hook: a chart pin missing from a reachable repo
  exits 2 (drift)`. No script changes — tests only, per the item's scope.

## Verification

This session's sandbox started with the wrong `yq` on `PATH` (the Python
`kislyuk/yq` jq-wrapper, not `mikefarah/yq`) and was missing `bats`, `helm`,
`kustomize`, `kubeconform`, `terraform`, `tflint`, `shellcheck`, and `yamllint`
entirely — installed the correct toolchain (`mikefarah/yq` + `bats-core` +
`kustomize`/`kubeconform`/`tflint`/`helm` via `go install` through the Go module
proxy; `terraform` via `releases.hashicorp.com`; `shellcheck`/`yamllint` via `apt`) to
validate for real rather than relying on GitHub Actions alone (mirrors the toolchain
gap noted in PR #431's `docs/done/2026-07-16-validate-scripts-bats-coverage.md`).

- `make ci` is fully green: 1827 bats assertions, 0 failures (including the 2 new
  ones), plus lint/kustomize/manifests/terraform all `PASS`.
- `tests/hook-scripts-coverage.bats` run in isolation: 42/42 pass.

## PR

https://github.com/tooming/k8s-anywhere/pull/432
