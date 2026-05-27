# ADR-0006 — Dashboards via Grafana native Git Sync (not the sidecar)

**Decision.** Manage Grafana dashboards with Grafana's **native Git Sync**, replacing
the k8s-sidecar + labelled-ConfigMap delivery. Git Sync points at the lab's own
**GitLab** via the OSS **Pure Git** repository type, so dashboards stay versioned in
the existing source of truth. Sync is **bidirectional**: edits in the UI are committed
back to GitLab, and changes in GitLab appear in Grafana.

**Why.** The sidecar path is one-way (git→cluster): UI edits are lost on restart, and
every dashboard must be wrapped as JSON-in-YAML inside a ConfigMap (friction + size
limits). Git Sync stores plain dashboard JSON in git, gives real history/diffs, and
makes "dashboards as code" the live workflow — the upstream-blessed observability-as-code
path, and exactly the kind of real-platform mechanism this lab exists to learn (ADR-0003).

**Relationship to ADR-0001 (explicit carve-out).** ADR-0001 stands: **ArgoCD remains the
sole reconciler for in-cluster workloads**, including Grafana itself and its Helm config.
ADR-0006 carves out **one scoped exception** — dashboard *content* is reconciled by
Grafana's own Git Sync loop, not ArgoCD. This is acceptable because dashboards are
content/data, not infrastructure; **GitLab stays the single source of truth** (the spirit
of ADR-0001 is preserved — only the reconciler differs); and the second loop is bounded
to dashboards. No new dependency cycle: Grafana↔GitLab does not touch ArgoCD's repo
credentials or Vault's unseal key (ADR-0001 corollary).

**Specifics.**
- Requires Grafana **v12+** with the `provisioning` + `kubernetesDashboards` feature
  toggles (and unified storage). The feature is GA but the Pure-Git / self-hosted-GitLab
  path is new (Feb 2026) and Grafana still flags it as not-for-prod — an accepted
  learning-lab risk, not a production claim (ADR-0004).
- **Pure Git** type (OSS). The *enhanced* GitLab integration (PR workflows, linking) is
  Enterprise/Cloud-only and is **not** used.
- Auth = a **GitLab Personal Access Token** kept in **Vault** (the existing api-scoped
  bootstrap token) and read by the Git Sync bootstrap seam, which hands it to Grafana via
  the Repository's `secure.token` (stored encrypted *inside* Grafana). No workload reads
  it at runtime, so no ExternalSecret is needed — the token never lands in git either way.
- Removes on cutover: the k8s-sidecar dashboard config, the
  `gitops/observability/dashboards/` ConfigMaps, and the `observability-dashboards`
  ArgoCD Application. **Community dashboards (gnetId) are unaffected** — separate provider.

**Status.** Accepted; **implementation pending** (Grafana version bump, provisioning
config, dashboard migration into git, sidecar removal, live verification). Moves to
*Adopted* only after Git Sync is verified working end-to-end (ADR-0004).
