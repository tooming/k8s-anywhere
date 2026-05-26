# ADR-0006 — (Proposed) Grafana Git Sync for dashboards, carved out of ArgoCD

**Status.** Proposed (evaluation). Needs a validation spike (below) and acceptance
before any implementation. Until then, dashboards stay on the scoped sidecar (PR #22).

**Context.** Lab dashboards are ConfigMaps in `gitops/observability/dashboards/`,
synced by ArgoCD and loaded into Grafana by the kube-sidecar. Grafana 12.3.1 ships
**Git Sync** (per Grafana docs, GA for OSS/Enterprise/Cloud): Grafana syncs dashboard
JSON to/from a Git repo **bidirectionally** (UI edits commit to Git; Git edits sync
into Grafana), polling (~60s) or via webhook. The question that gates adoption:
**can ArgoCD and Grafana conflict over dashboards?**

**The conflict is real, but ONLY under overlapping ownership.**
- **Double-write.** Keep the ConfigMaps *and* point Git Sync at the same dashboards
  → two controllers write the same dashboard into Grafana. Same UID = last-writer
  churn / "already exists"; different UID = duplicates in different folders.
- **Bidirectional vs declarative.** A UI edit makes Git Sync commit JSON to its repo,
  but the ArgoCD ConfigMap (different file/format/path) stays unchanged → two
  diverging git truths for one dashboard. If Git Sync commits into a path ArgoCD also
  watches, they ping-pong reconciliations.
- **Provisioning ownership.** Both the sidecar file-provider and Git Sync mark
  dashboards "provisioned"; overlapping folders/UIDs confuse Grafana about ownership.

**Decision (proposed).** If we adopt Git Sync, enforce **single ownership**:
Git Sync owns dashboard *content*; ArgoCD owns the Grafana *platform* (Deployment,
datasources, provisioning config, the Git Sync connection + its credential). Remove
the dashboard sidecar and the dashboard ConfigMaps from ArgoCD's scope. No resource
is written by both controllers → no conflict. The boundary: **ArgoCD owns the
platform, Git Sync owns the content.**

**Relationship to [ADR-0001].** ADR-0001: "every in-cluster workload is an ArgoCD
Application synced from GitLab." Git Sync delivers dashboard *content* by having
Grafana pull Git **directly**, outside ArgoCD — a deliberate **carve-out** for
dashboards (config, not a workload); the Grafana workload itself stays ArgoCD-managed.
This ADR exists to make that carve-out an explicit, accepted exception rather than
silent drift. Reject it → keep the scoped sidecar (PR #22).

**Open questions / validation spike (before accepting).**
- Enablement on OSS 12.3.1: which feature flags / app-platform / unified-storage
  settings does Git Sync actually require? Verify on the running build — do not assume
  (ADR-0004).
- Which repo Grafana writes to (GitHub vs the in-cluster GitLab ArgoCD reads), and how
  its write credential is issued — Vault → ExternalSecret, per the lab's secret pattern.
- Poll vs webhook: a localhost lab has no public ingress, so polling (~60s) is the
  default; webhook would need exposing Grafana.
- Migration: move the 7 dashboards into the Git Sync repo/path, delete the ConfigMaps +
  sidecar, confirm no duplicates and that the provisioned folder is correct.

**Alternatives.**
- **Keep the scoped sidecar (PR #22)** — ArgoCD-native, no new moving parts, status quo.
- **Static file provider + mounted ConfigMaps** — removes the watcher, but couples
  dashboards to the Grafana Deployment (restart to add one).
