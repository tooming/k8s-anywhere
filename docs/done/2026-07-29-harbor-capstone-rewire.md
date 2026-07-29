# Capstone pipeline re-wire — Artifactory → Harbor registry host

(CHARTER **Objective O4** + capstone RFC #62, RFC #297 / ADR-0024 — architect
decision 2026-06-30; **CI / security-adjacent changes pre-approved by ADR-0024
per WAYS-OF-WORKING.md §2**; **maintainer-confirmation prerequisite: pick up
ONLY after the maintainer confirms on #297 that the minimal Harbor profile was
measured on the live cluster and fits the 12 GB budget on-demand — the
ADR-0024 go/no-go gate, tracked as a standing `[Action required]` issue (#632,
stays open until confirmed); check it for a confirmation comment before
treating this as satisfied; skip to the next item if it cannot be verified this
run**). The registry-credential Secret (`auto/harbor-registry-secret-prep`)
and the Kargo egress NetworkPolicy widen (`auto/harbor-kargo-egress-prep`) are
already prepped, both above — this item is now scoped to the actual
live-state-mutating cutover only: `.gitlab-ci.yml` (registry host +
login — note the GitLab CI/CD variables it reads must be repointed at Harbor
creds by the maintainer outside this repo, since they're not GitOps-managed),
`gitops/kargo-project/project.yaml` (Warehouse `repoURL` — this is what
triggers Kargo's `argocd-update` promotion step against the live capstone
Application, so it stays gated alongside the image refs below, not split out),
`gitops/apps/capstone/rollout.yaml` + `deployment.yaml` (image refs +
`imagePullSecrets: harbor-registry`, now that the Secret exists),
`gitops/kyverno/policies/verify-image-signatures.yaml` (verifyImages scope
`artifactory.127.0.0.1.nip.io/**` → `harbor.127.0.0.1.nip.io/**` — independent
of the separate Audit→Enforce flip item, coordinate if both are open), and the
README / `docs/dependency-tree.md` references (and, once this lands, removing
the now-unused legacy-registry `namespaceSelector` from the NetworkPolicy the
prep item above widened). Update the relevant bats (capstone / kargo / kyverno)
for the new host. `make ci` must pass. `docs/done/` entry required.
**Executor note:** if this crosses ~400 lines, split the CI/registry-credential
cutover from the GitOps app/image-ref cutover. (auto/harbor-capstone-rewire)

## What shipped

The maintainer-confirmation gate (issue #632) was confirmed 2026-07-29 —
Harbor's minimal profile measures ~73m CPU / ~595Mi memory standalone, and the
cluster-wide footprint with Harbor running alongside the always-on stack is
~6.6GB/12GB (~55%), comfortably meeting the ADR-0024 12 GB gate. This PR
performs the actual cutover:

- `.gitlab-ci.yml`: `REGISTRY` → `harbor.127.0.0.1.nip.io`, `IMAGE_NAME` →
  `library/hello` (Harbor's built-in default project — no manual repository
  creation needed, unlike Artifactory's `docker-local`); CI variables renamed
  `HARBOR_USER` / `HARBOR_PASSWORD` (the maintainer must set these in GitLab →
  Settings → CI/CD → Variables, since they are not GitOps-managed).
- `gitops/kargo-project/project.yaml`: Warehouse `repoURL` and both Stage
  (`dev`, `prod`) `argocd-update` image overrides repointed at
  `harbor.127.0.0.1.nip.io/library/hello`.
- `gitops/apps/capstone/rollout.yaml` + `deployment.yaml`: image ref →
  `harbor.127.0.0.1.nip.io/library/hello:latest`; `imagePullSecrets` →
  `harbor-registry` (the Secret already exists from the prep slice).
- `gitops/kyverno/policies/verify-image-signatures.yaml`: verifyImages scope
  repointed to `harbor.127.0.0.1.nip.io/**`; rule renamed
  `verify-harbor-signatures`.
- `gitops/kargo/networkpolicy/allow-kargo-egress-registry.yaml`: removed the
  now-unused legacy `artifactory` namespaceSelector egress target — only
  `harbor` remains.
- `README.md` / `docs/dependency-tree.md`: capstone pipeline prose and graph
  edges repointed at Harbor; the standalone Artifactory Application/route
  references are left untouched (pending the separate
  `auto/harbor-artifactory-decommission` item).
- `tests/capstone.bats`, `tests/kargo.bats`, `tests/kyverno.bats`,
  `tests/cosign-bootstrap.bats`, `tests/networkpolicy-kargo.bats`: updated
  assertions for the new Harbor host/project/secret names, and an inverted
  assertion confirming the legacy egress selector is gone.

Out of scope (left for the separate, still-gated
`auto/harbor-artifactory-decommission` item): removing the Artifactory
manifests, Make targets, and the now-orphaned
`gitops/secrets/artifactory-registry-externalsecret.yaml`.

## PR

https://github.com/tooming/k8s-anywhere/pull/885
