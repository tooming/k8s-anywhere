# Close docs/dora-audit-readiness.md's open Kyverno `failurePolicy` question — confirmed `Fail` by default via Kyverno's own controller source

`docs/dora-audit-readiness.md`'s Pillar 1 Kyverno row (re-checked 2026-09-06)
confirmed `verify-image-signatures.yaml` explicitly sets `failurePolicy: Fail`,
but left an open question about the other 4 `ClusterPolicy` files
(`add-default-runasnonroot`, `add-default-seccomp`, `disallow-latest-tag`,
`require-pod-security-restricted`) — none of them set `failurePolicy`
explicitly (confirmed directly via `grep` across every file under
`gitops/kyverno/policies/`), so their actual webhook behavior on a Kyverno
outage depended on "Kyverno's own admission-controller default — not
independently verified live from this clusterless session."

## What was checked

Neither this lab's `gitops/platform/kyverno.yaml` Application (its
`valuesObject` has no `webhookConfiguration`/`failurePolicy` override) nor any
of the 4 policies sets a failure policy, so the answer depends purely on
Kyverno's own controller-code default. Fetched Kyverno's real source directly
from GitHub (`api/kyverno/v1/spec_types.go`, raw content, not a summary):

- The `Spec.FailurePolicy` field is deprecated in favor of
  `spec.webhookConfiguration.failurePolicy` — neither is set on any of the 4
  policies, so the deprecated field's own default logic still governs.
- Its `GetFailurePolicy()` method returns **`Fail`** when the field is `nil` —
  confirmed against the actual method body, not inferred from a doc summary.

This is a primary-source, clusterless-verifiable answer: the *logic that
computes the default* is unambiguous in the controller's own code, independent
of any live cluster state. What remains genuinely unverified from this
sandbox (correctly flagged in the updated row, not overclaimed per ADR-0004)
is whether this exact chart version's *live-rendered*
`ValidatingWebhookConfiguration` object actually reflects that default with no
other override in play — that would need a live cluster to inspect directly.

## Outcome

Updated the Kyverno row: all 5 `ClusterPolicy` files in this lab are
fail-closed by default, not just `verify-image-signatures` — a stronger
security posture than the row previously documented. Still tiered P1
(unchanged): a Kyverno outage still blocks legitimate admission of new/updated
resources cluster-wide, the flip side of being fail-closed, independent of
which specific policies are affected.

No code/config change — pure doc correction, closing a real open question the
doc itself had flagged rather than leaving it unresolved indefinitely.

Found via the executor's STEP 6b fallback chain (this run's sixth consecutive
cycle with a fully-gated "Now / next" lane — tried yet another lens per STEP
8's "widen it" guidance: re-reading `docs/dora-audit-readiness.md` for any
row explicitly marked as an open/unresolved question, after currency checks,
a bats-test cleanup, and a Makefile help-text sweep had already been tried
this run).

## PR

(filled in once the PR is opened)
