# Harbor registry ExternalSecret — capstone imagePullSecret prep (split-the-gate)

**Governance fix + real split-the-gate demonstration.** ROADMAP.md's `Now / next`
lane was fully gated on live-cluster maintainer confirmations for the entirety of this
session — every item needed either the verifyImages Enforce-flip live check, the
Harbor footprint measurement, or a Kargo promotion having been exercised on a real
cluster. The session's first several hours walked the (then-existing) fallback chain
in order and shipped six real PRs (#431, #433, #434, #435, #436, #437) — but every one
was test coverage or a new CI drift gate, zero progress toward the actual gated CHARTER
work. The maintainer flagged this directly: repo maintenance was substituting for real
development.

## Root cause + governance fix

ROADMAP.md rule #9's fallback chain listed `split-the-gate` as the *last* named check,
after `coverage/hardening` — and coverage/hardening is explicitly inexhaustible ("large
and slow-growing, not empty"), so it's always available and easy to reach for, while
split-the-gate requires actually reading the gated item closely enough to find a real,
safe, ungated slice. This PR rewrites rule #9: instead of a fixed ordered checklist of
named checks, it states the priority directly (CHARTER progress via split-the-gate is
the default move on a gated `Now / next`; doc-drift/coverage/triage work is filler for
when there's genuinely nothing left to push on the actual blockers, not the first place
to look) and cites this exact run as the precedent for why the checklist ordering
failed. Also simplified per direct maintainer feedback mid-session ("remove the chain
altogether and let the agent decide on-the-go") — the previous edit to this rule still
carried a long enumerated sub-checklist; this version trusts judgment instead.

## The demonstration: a real split-the-gate slice

Re-examined the topmost gated item, `auto/harbor-capstone-rewire` ("Capstone pipeline
re-wire — Artifactory → Harbor registry host"), instead of accepting "it's all one
atomic action" on a first pass. It bundles several changes; sorting them by whether
they mutate **live-synced cluster state**:

- **Live-mutating (stays gated):** `gitops/apps/capstone/rollout.yaml` +
  `deployment.yaml` image refs (the auto-synced Application ArgoCD reconciles onto the
  running workload); `gitops/kargo-project/project.yaml`'s Warehouse `repoURL` (Kargo
  polls this and its `argocd-update` promotion step *automatically* mutates the live
  capstone Application on a new digest — this is why it stays gated alongside the image
  refs, not split out with the CI-side changes as the item's own executor-note
  initially suggested); the Kyverno `verifyImages` scope (admission-enforcement
  behavior change).
- **Additive, clusterless-verifiable (safe to build now):** a new
  `harbor-registry` ExternalSecret rendering `secret/harbor/registry` (already seeded
  by the separately-shipped `auto/harbor-bootstrap-credentials` item) into a
  `kubernetes.io/dockerconfigjson` Secret — as long as nothing references it yet in
  `imagePullSecrets`, it changes zero running-workload behavior. Verified this
  explicitly before landing it: `tests/harbor-bootstrap.bats` asserts the Secret name
  does **not** appear anywhere under `gitops/apps/capstone/`.

## What shipped

- `gitops/secrets/harbor-registry-externalsecret.yaml`: new ExternalSecret, mirrors the
  existing registry-credential ExternalSecret's shape exactly, targets
  `harbor.127.0.0.1.nip.io`, namespace `capstone`.
- Seven new `tests/harbor-bootstrap.bats` cases: manifest exists, correct namespace,
  correct Secret name/type, correct registry host in the rendered `auths` key, correct
  Vault path, correct `ClusterSecretStore`, and — the one that actually proves the
  "additive, no live behavior change" claim — asserts the new Secret name is not yet
  referenced anywhere under `gitops/apps/capstone/`.
- `docs/dependency-tree.md`: new row documenting the edge, explicitly marked
  "prep-only" / "not yet referenced."
- ROADMAP.md: split `auto/harbor-capstone-rewire` into this now-checked-off prep item
  plus a trimmed remaining gated item — the remainder is now scoped to only the
  live-mutating pieces, and its own text records why the Kargo `Warehouse` change
  couldn't be split out with the CI-side work (it auto-triggers a live promotion, unlike
  a CI config change which only fails a build if wrong).

## Verification

`bash scripts/validate-manifests.sh` (kubeconform) and `bash scripts/validate-kustomize.sh`
both pass on the new manifest. `tests/harbor-bootstrap.bats` in isolation: 23/23 pass.
`shellcheck`/`yamllint` clean. Full `make ci` passes.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
