# Dedicated least-privilege RBAC + kubeconfig runbook for the O4 `verify-rejection` CI job

Issue #1229 (`[Action required] Set the KUBECONFIG Forgejo Actions secret for
the O4 CI rejection-gate job`) has two halves. PR #1402 did the first —
restoring the silently-dropped `verify-rejection` job and its bats guard. This
PR does the second **executor-buildable** slice: the ServiceAccount / Role /
RoleBinding the job's kubeconfig binds to, which issue #1229 explicitly names as
"part of this ask" ("a Role scoped to capstone + a RoleBinding for a dedicated
ServiceAccount ... no such Role/ServiceAccount exists yet either").

What still needs a live-cluster session (issue #1229 stays **open**): minting a
token, assembling the kubeconfig, pasting it as the Forgejo Actions secret, and
watching a real workflow run report `PASS: unsigned image was correctly rejected
at admission`. That is now a mechanical checklist, not a design task —
`docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md`.

## What changed

- **`gitops/apps/capstone/ci-verify-rejection-rbac.yaml`** (new, wired into
  `kustomization.yaml`): ServiceAccount `ci-verify-rejection` +
  namespace-scoped Role (`create`/`delete`/`get`/`list` on `pods` in `capstone`
  only) + RoleBinding. `automountServiceAccountToken: false` (nothing in-cluster
  mounts it — the token is minted out-of-band for CI). No ClusterRole, no
  `secrets`/`deployments` access — the job only ever `kubectl apply`s a test Pod
  (expected to be denied by Kyverno) and deletes it.
- **`.forgejo/workflows/build-sign-push.yml`**: header prerequisite #7 now
  points at the GitOps-managed RBAC and the step-by-step runbook instead of just
  saying "generate a kubeconfig somehow".
- **`docs/runbooks/2026-09-04-ci-verify-rejection-kubeconfig.md`** (new):
  5-step runbook — confirm RBAC synced → `kubectl create token` → build
  kubeconfig from the cluster's own CA/endpoint → `kubectl auth can-i`
  least-privilege sanity check → set the Forgejo secret → trigger + confirm →
  close #1229. Appendix covers a non-expiring bound-Secret token.
- **`tests/capstone.bats`**: 6 assertions pinning the RBAC's presence,
  kustomization wiring, exactly-three-kinds shape, namespace scoping (guards
  against a silent widen to ClusterRole), the pods-only verb set, the
  no-automount flag, and the runbook link — mechanical recurrence guard, same
  failure class that removed the `verify-rejection` job itself (PR #1402).

## Verification

- `bats tests/capstone.bats` — 43/43 pass (6 new).
- `bats tests/forgejo-ci.bats` — 41/41 pass (header-comment edit only, no job
  logic touched).
- `kustomize build gitops/apps/capstone/` renders the SA/Role/RoleBinding
  cleanly alongside the existing workload.
- `make kustomize-orphan-check`, `yamllint` — clean.
- `make ci` — green.

## Caveat (ADR-0004)

This clusterless session cannot apply the RBAC to a live cluster, mint a token,
or execute a Forgejo Actions run. The manifest is structurally validated only;
the remaining live confirmation stays tracked on issue #1229.

## PR

https://github.com/tooming/k8s-anywhere/pull/1403
