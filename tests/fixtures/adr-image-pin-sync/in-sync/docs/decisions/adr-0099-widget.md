# ADR-0099 — Widget (fixture)

## Decision

A pinned official `widget:1.2.3-management` image in a plain `StatefulSet`.

## Files

| Path | Role |
|------|------|
| `gitops/platform/widget.yaml` | ArgoCD Application (auto-synced) |
| `gitops/platform/widget/statefulset.yaml` | Single-node widget, persistent `/data` |
