# Quality-gate validator scripts — bats coverage gap closed

**Coverage/hardening fallback run** (ROADMAP.md's `Now / next` lane was fully starved
this run — every remaining unchecked item is gated on a live-cluster maintainer
confirmation, or a prerequisite item that is itself gated the same way, or (the one 🟡
item) explicitly marked "executor skips this item" pending a chart change that hasn't
happened. Per ROADMAP.md rule #9's fallback chain, the coverage/hardening lane surfaced
real, buildable, clusterless work instead of an idle declaration.)

## Gap found

Three of the `make ci`-wired quality-gate scripts had **zero** bats coverage:
`scripts/validate-kustomize.sh`, `scripts/validate-manifests.sh`,
`scripts/validate-terraform.sh`. All three gate every PR (`make ci`'s
kustomize/manifests/terraform jobs, mirrored in `.github/workflows/ci.yml`) and share
the same local-skip-vs-CI-required pattern (`if [ "${CI:-}" = "true" ]; then ... exit 1;
else ... skip ... exit 0; fi`) as every other drift-detector script in the repo, but
unlike those, nothing asserted the pattern itself was intact. A dropped `${CI:-}` check
in any of the three would silently turn a required CI gate into an always-green no-op
with no test catching the regression — `make ci` only exercises the scripts' happy
path (tools present, manifests valid), never the "tool missing" branch that CI actually
depends on to fail loudly when its own setup step breaks.

## What shipped

New `tests/validate-scripts.bats` (21 assertions), mirroring the existing
`tests/lab-ops-scripts.bats` precedent:

- **Existence + executable bit** for all three scripts.
- **Real behavioral coverage of the tool-missing branch** — a `PATH` stripped of
  `kustomize`/`kubeconform`/`terraform` (computed once in `setup()`, filtering the
  test's own `PATH` rather than hardcoding a path list) drives each script down its
  actual "not installed" code path with no mocking: local (`CI` unset) asserts exit 0 +
  a "skipping" message, `CI=true` asserts exit 1 + a "required in CI" message. This
  exercises the real script logic, not a stand-in.
- **Structural regression guards** for the behavior each script's own header comment
  documents as load-bearing: `validate-kustomize.sh`'s `--load-restrictor
  LoadRestrictionsNone` build flag and its `find gitops/ -name kustomization.yaml` walk;
  `validate-manifests.sh`'s `-ignore-missing-schemas` flag and the Invalid-vs-Errors
  distinction (a kubeconform schema-fetch rate-limit must never fail the gate, only an
  actually-invalid manifest may); `validate-terraform.sh`'s whole-tree `fmt -check
  -recursive`, its provider-registry-unreachable-is-a-skip-not-a-failure behavior, and
  tflint's CI-required-but-locally-optional status.
- **Makefile wiring assertions**: the `ci` target invokes all three scripts; the
  `validate` target invokes the two of them it uses.

## Verification

This session's sandbox started with the wrong `yq` on `PATH` (Debian's `python-yq`
jq-wrapper, not `mikefarah/yq` — the two disagree on scalar-output quoting and
`python-yq` doesn't support the `| tag` filter several existing bats cases rely on) and
was missing `kustomize`/`kubeconform`/`terraform`/`tflint`/`helm` entirely, causing
several *pre-existing, unrelated* test failures on the very first `make ci` run before
this change touched anything. Installed the correct toolchain this session:
`mikefarah/yq` v4.53.3, `kustomize` v5.8.1, `kubeconform`, `tflint` v0.63.1, and `helm`
v3.21 all via `go install` through the Go module proxy (raw `github.com` release
downloads are blocked by this session's repo-scope proxy allowlist, but the Go module
proxy is not); `terraform` v1.9.8 via `releases.hashicorp.com` (also unblocked). With
the full toolchain in place, `make ci` is fully green: 1846 bats assertions, 0
failures, including all 21 new ones.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
