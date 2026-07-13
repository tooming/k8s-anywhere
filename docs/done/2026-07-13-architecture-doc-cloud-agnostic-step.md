# `docs/00-architecture.md` — add learning-path step 12 for cloud-agnostic infrastructure design

Self-caught CHARTER **Goals** gap: earlier this session, CHARTER.md's Goals section was
edited to add "cloud-agnostic infrastructure design — why the GitOps layer never encodes
a backend" as a learning outcome (alongside ADR-0026's cloud-agnostic pivot). A later PR
in the same session added learning-path steps 10–11 to `docs/00-architecture.md` for two
*other* Goals gaps (DR/blue-green, GitOps promotion) but missed this one — an
inconsistency across two of this session's own changes, caught on review rather than
left for a future planner run to find.

Adds **Step 12 — Cloud-agnostic infrastructure design**: explains that `argocd`/`gitlab`
Terragrunt units depend only on the `cluster` unit's `kube_context`/`cluster_name`/
`api_endpoint` outputs, never on which backend produced them — which is why steps 1–11
run identically whether `cluster/` is `local/` (k3d) or `oracle/` (Oracle Cloud Always
Free + k3s). Cites `infra/live/README.md`'s contract, ADR-0026, and ADR-0027.

Docs-only, no code changes.

## PR

https://github.com/tooming/k8s-anywhere/pull/387
