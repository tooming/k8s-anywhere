# sync(docs): reconcile three stale in-file comments

Doc-drift-author sweep (executor STEP 6b fallback — the "Now / next" lane was
gated again this cycle; a fresh sweep for stale "follow-up" markers across
`gitops/` found three genuinely stale comments, each independently verified
against the current repo state before fixing).

## Drift found and fixed

1. **`gitops/external-secrets/networkpolicy/allow-eso-webhook-from-apiserver.yaml`**
   — claimed "the other three webhook-from-apiserver.yaml files carry the same
   latent bug... tracked for a follow-up fix." Verified: `gitops/kyverno`,
   `gitops/cert-manager`, and `gitops/keda`'s equivalent files are all already on
   the correct `CiliumNetworkPolicy` + `fromEntities: remote-node` shape (grepped
   each directly). No follow-up fix remains outstanding — updated the comment to
   say so.
2. **`gitops/argo-rollouts/networkpolicy/allow-argo-rollouts-metrics-from-observability.yaml`**
   — claimed "the Alloy scrape job will target this once the follow-up
   dashboard+scrape PR lands." Verified: the `argo-rollouts` scrape job already
   exists in `gitops/platform/observability-alloy.yaml`, and
   `grafana/dashboards/lab-argo-rollouts.json` already exists. Updated the comment
   to reference the real, landed state instead of a future promise.
3. **`gitops/kyverno/policies/verify-image-signatures.yaml`** — claimed Audit mode
   applies "until the cosign signing step in `.gitlab-ci.yml` is wired." Verified:
   the `sign-image` stage already exists in `.gitlab-ci.yml` (cosign signing is
   wired). The actual reason this policy stays in Audit mode is the separate,
   still-gated `auto/cosign-enforce-flip` ROADMAP item (needs a maintainer to
   confirm on a live cluster that a signed image was actually pushed). Updated the
   comment to name the real blocker instead of the already-resolved one.

All three matched a pattern already flagged (but not acted on, since it was
"cosmetic only, not worth a PR on its own") by the planner's 2026-07-17 gap
analysis (issue #473) — bundling all three together into one small, real doc-drift
PR crosses that bar.

## Mirrors reality, never invents it

Every claim in the corrected comments was independently re-verified against the
actual current file contents before writing (per ADR-0004) — not copied from the
planner's prior note without checking.

## ADR-0024 note

Item 3's corrected comment still mentions "Artifactory" — the existing,
already-in-use, not-yet-migrated registry this policy's (unchanged)
`artifactory.127.0.0.1.nip.io/**` scope already targets. No new decision to use
Artifactory is made; the actual Harbor migration is tracked separately
("Capstone pipeline re-wire — Artifactory → Harbor registry host").

`make ci` passes — no topology or behavior changed, comment-only.

## PR

https://github.com/tooming/k8s-anywhere/pull/514
