# kro namespace — PSS restricted + NetworkPolicy overlay

**CHARTER Objective O2** (PSS-restricted fan-out + NetworkPolicy floor, due 2026-09-30).

Applies Pod Security Admission `restricted` profile to the `kro` namespace and adds a
default-deny NetworkPolicy overlay (ADR-0016 §4, ADR-0017 §"Per-namespace profile").

The KRO controller chart (`gitops/platform/kro.yaml` valuesObject) already ships with
a fully hardened `podSecurityContext` (runAsNonRoot: true, UID 65534, seccompProfile
RuntimeDefault) and `containerSecurityContext` (allowPrivilegeEscalation: false,
readOnlyRootFilesystem: true, capabilities.drop: [ALL]) — no workload securityContext
patch was needed in this PR.

## Files delivered

| Path | Role |
|------|------|
| `gitops/kro/namespace.yaml` | New Namespace manifest with all four PSA `restricted` labels |
| `gitops/platform/kro-extras.yaml` | New ArgoCD `Application` (sync-wave 0, `ServerSideApply=true`, `CreateNamespace=false`) — SSA-patches labels onto the namespace before any pod is scheduled |
| `gitops/kro/networkpolicy/kustomization.yaml` | NetworkPolicy Kustomize overlay: baseline templates + `allow-kro-ack-egress.yaml` |
| `gitops/kro/networkpolicy/allow-kro-ack-egress.yaml` | Egress allow from kro pods to `ack-system` namespace (KRO reconciles ACK S3 Bucket CRs via its S3BucketClaim RGD) |
| `gitops/platform/networkpolicy-appset.yaml` | Added `kro-networkpolicy` entry to the list generator (`gitPath: gitops/kro/networkpolicy`, `destNamespace: kro`) |
| `docs/decisions/adr-0017-pod-security-standards-restricted.md` | Added `kro → restricted` row to §"Per-namespace profile" table |
| `tests/securitycontext-kro.bats` | 9 structural assertions in their own per-scope file (namespace exists, four PSA restricted labels, kro-extras Application exists, targets correct path, uses ServerSideApply, CreateNamespace=false) |
| `tests/networkpolicy-kro.bats` | 8 assertions covering the kro overlay structure + appset entry — in their own per-scope file (the `tests/networkpolicy.bats` monolith was split, see below) |
| `ROADMAP.md` | Item checked `[x]` |

## Conflict resolution + recurrence guards

Merging this PR onto `main` surfaced a conflict in `tests/networkpolicy.bats`: this
branch and the already-merged #247 (external-secrets) each appended a `@test` block to
the same monolith's EOF — an unmergeable collision. Two recurrence guards were added so
this class cannot return:

- **NetworkPolicy test monolith split (structural).** `tests/networkpolicy.bats` was
  refactored into per-scope files (`tests/networkpolicy-<scope>.bats`, one per namespace
  overlay) sharing `tests/lib/networkpolicy-paths.bash`; the monolith now holds only the
  shared baseline-template tests. With no shared append anchor, parallel fan-out PRs can
  no longer collide. `scripts/networkpolicy-tests-check.sh` (in `make ci` + a PostToolUse
  hook) fails if a per-namespace test (`namespace overlay` header or a `$<NS>_NP` path
  var) ever reappears in the baseline file.
- **yq quoting guard.** A latent `tests/argocd-resources.bats` bug surfaced: yq variants
  quote scalars differently (`"250m"` vs `250m`), breaking the millicore arithmetic on
  the container's yq. Scalar reads now route through `yqs()` in `tests/lib/yq.bash`;
  `scripts/yq-raw-check.sh` (in `make ci` + a PostToolUse hook) forbids bare `yq` calls
  in bats tests. Both guards have golden in-sync/drift fixtures + coverage in
  `tests/drift-detectors.bats`.

## PR

PR #248 — https://github.com/tooming/k8s-lab/pull/248
