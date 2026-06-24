# ArgoCD PSS Phase 2 — securityContext hardening + enforce flip

🟢 **ArgoCD PSS Phase 2 — securityContext hardening + enforce
flip** (CHARTER **Objective O2**, RFC #205 — Phase 2; buildable after
Phase 1 is **verified green in cluster** by maintainer). Update
`infra/modules/argocd/values.yaml` adding the exact
`global.podSecurityContext` + `global.containerSecurityContext` block
from RFC #205 §Decision (`runAsNonRoot: true`, `runAsUser/Group: 1000`,
`seccompProfile.type: RuntimeDefault`; `allowPrivilegeEscalation:
false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`);
add `emptyDir` at `/tmp` for `repoServer` (git clone scratch) and
`server` (session token files) via `volumes` + `volumeMounts`. Update
`gitops/argocd/namespace.yaml` to add `enforce: restricted` +
`enforce-version: latest`. Verify the bundled `argocd-redis`
sub-chart's own securityContext is not adversely overridden by the
global block — add per-component override if needed. Extend
`tests/securitycontext.bats` asserting `enforce: restricted` label is
present in `gitops/argocd/namespace.yaml`. `docs/done/` entry required.
**Executor note:** the `infra/` touch is 🟡 by default, but RFC #205
(the architect's binding decision per WAYS-OF-WORKING.md §2) explicitly
names this `infra/` change as part of the implementation spec — the
RFC IS the approval; no additional human sign-off needed before
building. (auto/argocd-pss-enforce)

## PR

#268 — https://github.com/tooming/k8s-lab/pull/268
