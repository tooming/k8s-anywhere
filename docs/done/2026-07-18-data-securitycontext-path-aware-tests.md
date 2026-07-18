# Convert data-namespace securityContext recurrence guards to path-aware yqs()

Janitor fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated again this cycle; no un-RFC'd 🟡 items, no un-absorbed architect RFCs,
no open issues for the triager, no fresh upgrade-drafter candidate this pass
through the chain). Continues the recurrence-guard hardening sweep (PRs
#541 vault, #542 moto/ack-s3/kro) across the remaining `securitycontext-*.bats`
files that still use bare `grep -q`.

## What was found

`tests/securitycontext-data.bats` had 20 bare-`grep -q` `securityContext`
field assertions across four plain Kubernetes workloads in the `data`
namespace: the `rabbitmq` and `valkey` StatefulSets, and the
`rabbitmq-load`/`valkey-load` demo Deployments. Same gap as the prior two
cycles: a value string existing anywhere in the file passes the test even
nested under a wrong key.

## What changed (behavior-preserving)

Converted 20 assertions to path-aware `yqs()` reads. All four are plain
Kubernetes Deployment/StatefulSet manifests (no Helm `valuesObject`
indirection), so the path is the same standard shape for all four:
`.spec.template.spec.securityContext.*` (pod-level) and
`.spec.template.spec.containers[0].securityContext.*` (container-level) —
confirmed against each of the four source files directly. Same 25 tests,
same pass/fail outcome against current manifests.

## Validation

`bats tests/securitycontext-data.bats` — 25/25 pass locally. `make ci` —
same known pre-existing local bats failures as every prior cycle this
session (sandbox bats/yq toolchain mismatch, unrelated to this change).
GitHub Actions is the authoritative gate for this PR.

## PR

https://github.com/tooming/k8s-anywhere/pull/543
