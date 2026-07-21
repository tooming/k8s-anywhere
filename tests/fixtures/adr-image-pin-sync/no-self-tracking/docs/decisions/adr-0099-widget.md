# ADR-0099 — Widget (fixture)

## Decision

Run Widget from the `widget/widget` Helm chart, `v1.2.3` (latest stable at
executor pickup time) — a point-in-time record, not a live mirror.

## Files

| Path | Role |
|------|------|
| `gitops/platform/widget.yaml` | ArgoCD Application (auto-synced) |
