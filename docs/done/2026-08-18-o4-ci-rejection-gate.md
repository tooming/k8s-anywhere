# O4 CI gate — `verify-image-rejection` job

CHARTER **Objective O4**, due **2026-12-31**; RFC #289 — architect decision 2026-06-27;
executor pickup 2026-08-18, fourth cycle this run, immediately after
`auto/cosign-enforce-flip` (PR #1223) merged in the prior cycle — the prerequisite check
`grep -q "validationFailureAction: Enforce" gitops/kyverno/policies/verify-image-signatures.yaml`
returns 0.

## Retargeting

This item's original spec named the prior CI pipeline file and registry host this repo
has since moved off of (ADR-0024's Harbor migration, ADR-0035's CI-source migration).
Building that text verbatim would add dead config that never runs against the actual
live pipeline — an ADR-0004 violation (presenting non-functional content as real).
Instead, added the `verify-rejection` job directly to
`.forgejo/workflows/build-sign-push.yml` (the real live pipeline, confirmed live by the
exact evidence chain `auto/cosign-enforce-flip`'s PR used) after `sign-image`, using
Harbor throughout.

## PSS-restricted interaction (found live, not in the original spec)

The `capstone` namespace enforces Pod Security `restricted`
(`gitops/apps/capstone/namespace.yaml`) — a bare `kubectl run` without a compliant
`securityContext` would be rejected by Kubernetes' own Pod Security admission *before*
Kyverno's `verifyImages` rule ever evaluates the image. That would make the test pass
for the wrong reason, never actually exercising cosign verification. The test Pod
mirrors `gitops/apps/capstone/rollout.yaml`'s own PSS-restricted `securityContext`
exactly (`runAsNonRoot`, `runAsUser`/`runAsGroup: 10001`, `fsGroup: 10001`,
`seccompProfile: RuntimeDefault` at the pod level; `allowPrivilegeEscalation: false`,
`privileged: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]` at the
container level) plus its `harbor-registry` `imagePullSecret`, so the *only* thing that
can block admission is the missing signature.

Used a full `kubectl apply -f -` Pod manifest (heredoc) rather than
`kubectl run --overrides` for an unambiguous, directly-readable spec.

The Pod's `image:` field intentionally omits the `:8080` port the CI job's own `docker
push` needs — matches `gitops/apps/capstone/rollout.yaml`'s own no-port image
reference (`harbor.127.0.0.1.nip.io/library/hello:latest`, no port). The cluster
resolves the registry host directly on its default port; the CI job's own network
position needs the k3d gateway's published `:8080` host port instead (same reasoning
already documented in the workflow file's `REGISTRY` env-var comment). The underlying
Harbor image identity (project `library`, repository `test-unsigned`) is the same
regardless of which host:port alias pushed it.

## New maintainer prerequisite

A `KUBECONFIG` Forgejo Actions secret (a service-account kubeconfig scoped to at least
create/delete Pod in `capstone`), documented in the workflow file's own header comment
alongside the existing `HARBOR_USER`/`HARBOR_PASSWORD`/`COSIGN_KEY`/`CHECKOUT_TOKEN`
secrets. Generating and verifying this kubeconfig is a live-cluster action this remote
session cannot perform — left as an explicit, undone prerequisite (ADR-0004), not
asserted as already configured.

## Tests

Extended `tests/forgejo-ci.bats` (this repo's existing convention already covers
`build-sign-push.yml` there — a separate `tests/gitlab-ci.bats`, as the original spec
named it, would itself have named the retired CI host, tripping this repo's own
`adr-guard-hook.sh`). 9 new assertions:
- the job exists and `needs: sign-image`
- explicit `timeout-minutes`
- pushes a distinct unsigned test-image tag, never the real signed app image
- the test Pod's securityContext is PSS-restricted compliant
- the test Pod uses the `harbor-registry` imagePullSecret
- the admission-failure check greps for a real Kyverno rejection reason, not just a
  non-zero exit
- the job fails loudly if the unsigned image is wrongly admitted
- the `KUBECONFIG` secret is referenced (no plaintext)
- the test Pod is cleaned up even on failure (`if: always()`)

`make ci` passes: full local suite green (bats installed this session via `apt-get`),
including all 25 `tests/forgejo-ci.bats` assertions (9 new).

## Caveats (ADR-0004)

This remote clusterless session cannot execute a real Forgejo Actions run to confirm
this job behaves correctly end-to-end — same caveat this workflow file's own header
comment already carries for `build-and-push`/`sign-image` (structurally authored and
validated, not live-executed). Two mechanics specifically need a live run to confirm:
(a) the `KUBECONFIG` secret's kubeconfig actually authenticates and has the right RBAC
once the maintainer sets it up; (b) the exact grep-matched rejection message Kyverno's
webhook returns for a real admission denial (the keyword set mirrors the original
item's own spec, not independently re-derived from a live rejection this session
observed).

## PR

https://github.com/tooming/k8s-anywhere/pull/1224
