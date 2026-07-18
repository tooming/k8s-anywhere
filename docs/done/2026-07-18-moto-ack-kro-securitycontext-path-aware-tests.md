# Convert moto/ack-s3/kro securityContext recurrence guards to path-aware yqs()

Janitor fallback (executor routine, STEP 6b — ROADMAP `Now / next` fully
gated again this cycle; no un-RFC'd 🟡 items, no un-absorbed architect RFCs,
no open issues for the triager, no fresh upgrade-drafter candidate available
this pass through the chain). Continuation of the recurrence-guard hardening
sweep started in the vault cycle (PR #541) — the same bare-`grep -q` gap
class exists across most `tests/securitycontext-*.bats` files.

## What was found

`tests/securitycontext-moto-ack-labgateway.bats` had 16 bare-`grep -q`
`securityContext` field assertions across three components (the hand-written
`moto` Deployment, and the `ack-s3` and `kro` Helm Applications) — unable to
distinguish a value correctly nested under the right key from the same
string appearing anywhere else in the file. The namespace PSA-label
assertions (each targeting a single-purpose namespace manifest) were left
as-is — low collision risk, no securityContext nesting involved.

## What changed (behavior-preserving)

Converted 16 assertions to path-aware `yqs()` reads, verified against each
source's real schema:
- `gitops/moto/deployment.yaml` (plain Deployment): `.spec.template.spec.securityContext.*` (pod) / `.spec.template.spec.containers[0].securityContext.*` (container).
- `gitops/platform/ack-s3.yaml` (ACK S3 Helm chart): `.spec.source.helm.valuesObject.podSecurityContext.*` / `.securityContext.*` (top-level under `valuesObject`, no extra nesting).
- `gitops/platform/kro.yaml` (KRO Helm chart): `.spec.source.helm.valuesObject.deployment.podSecurityContext.*` / `.deployment.securityContext.*` — this chart nests one level deeper, under `deployment.`, than ack-s3's schema; confirmed by reading the actual pinned manifest rather than assuming symmetry between charts.

Same 31 tests, same pass/fail outcome against current manifests — this
strengthens existing coverage only.

## Validation

`bats tests/securitycontext-moto-ack-labgateway.bats` — 31/31 pass locally.
`make ci` — same known pre-existing local bats failures as every prior
cycle this session (sandbox bats/yq toolchain mismatch, unrelated to this
change). GitHub Actions is the authoritative gate for this PR.

## PR

https://github.com/tooming/k8s-anywhere/pull/542
