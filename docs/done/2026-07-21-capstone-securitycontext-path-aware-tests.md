# Convert capstone Deployment securityContext recurrence guards to path-aware yqs()

Janitor fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated again this cycle: all five remaining `[ ]` items are blocked on the
standing maintainer-confirmation issues #631/#632/#633, all three still
open with zero comments; the planner/architect/doc-drift/triager lenses all
came up empty too — no ungroomed issues, no un-RFC'd 🟡 items, no drift, no
untriaged issues). Continuation of the recurrence-guard hardening sweep
started with vault (PR #541) and continued with moto/ack-s3/kro (PR #542):
a repo-wide sweep of every `tests/securitycontext*.bats` file for the same
bare-`grep -q` key-mismatch gap found that every remaining
`tests/securitycontext-<scope>.bats` file (argo-rollouts, artifactory,
capstone-pipeline, cert-manager, envoy-gateway-system, harbor, inkless,
istio, kargo, keda, lab-demo, longhorn, node-exporter, trivy-system, velero)
only asserts flat PSA namespace labels and Application shape fields — none
of those have the nested-key ambiguity the earlier fixes targeted, so they
were correctly left alone. The one real remaining instance was in the
shared, FROZEN `tests/securitycontext.bats` monolith itself: the capstone
Deployment's five pod/container `securityContext` assertions (lines 49–78)
still used bare `grep -q`, unable to distinguish a value correctly nested
under `.spec.template.spec.securityContext`/`.containers[0].securityContext`
from the same string appearing anywhere else in the file — the exact gap
class that let the KSM/node-exporter/Pyroscope/Grafana/KRO key mismatches
ship silently green (see docs/done/2026-07-18-securitycontext-key-guard-hardening.md).

## What changed (behavior-preserving)

Converted the five capstone Deployment assertions in `tests/securitycontext.bats`
to path-aware `yqs()` reads, scoped with `select(.kind == "Deployment")`
since `gitops/apps/capstone/deployment.yaml` is a multi-document file
(Deployment + Service) and an unscoped query would evaluate against both
documents. Verified each path against the real manifest:
`.spec.template.spec.securityContext.{runAsNonRoot,seccompProfile.type}`
(pod-level) and
`.spec.template.spec.containers[0].securityContext.{allowPrivilegeEscalation,readOnlyRootFilesystem,capabilities.drop[0],privileged}`
(container-level). The "does not run as privileged" test changed from
asserting grep exit-status 1 (absence of the string) to asserting the real
value equals `false` — a stronger, path-aware equivalent of the same check.

Test titles are byte-for-byte unchanged (only test bodies changed), so
`scripts/securitycontext-tests-check.sh`'s FROZEN title-snapshot guard
stays green with no `make securitycontext-tests-mark` needed — verified by
running the check script directly. Same five tests, same pass/fail outcome
against the current manifest — this strengthens existing coverage only, no
manifest or behavior change.

## Validation

`bash scripts/securitycontext-tests-check.sh` — clean (frozen title set
unchanged). All five new `yq` queries manually verified against
`gitops/apps/capstone/deployment.yaml` to return the expected values
(`true`, `RuntimeDefault`, `false`, `true`, `ALL`, `false`). `make ci` —
fully green locally (bats/kustomize/kubeconform/terraform/shellcheck/
yamllint aren't installed in this remote sandbox and gracefully skip, same
as every prior cycle this session; GitHub Actions is the authoritative gate
for the bats run itself).

## PR

See PR link on the branch `chore/capstone-securitycontext-path-aware-tests`.
